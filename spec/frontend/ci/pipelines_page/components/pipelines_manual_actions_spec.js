import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import mockPipelineActionsQueryResponse from 'test_fixtures/graphql/pipelines/get_pipeline_actions.query.graphql.json';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import PipelinesManualActions from '~/ci/pipelines_page/components/pipelines_manual_actions.vue';
import getPipelineActionsQuery from '~/ci/pipelines_page/graphql/queries/get_pipeline_actions.query.graphql';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('Pipeline manual actions', () => {
  let wrapper;
  let mock;

  const queryHandler = jest.fn().mockResolvedValue(mockPipelineActionsQueryResponse);
  const {
    data: {
      project: {
        pipeline: {
          jobs: { nodes },
        },
      },
    },
  } = mockPipelineActionsQueryResponse;

  const mockPath = nodes[2].playPath;

  const createComponent = (limit = 50) => {
    wrapper = shallowMountExtended(PipelinesManualActions, {
      provide: {
        fullPath: 'root/ci-project',
        manualActionsLimit: limit,
      },
      propsData: {
        iid: 100,
      },
      stubs: {
        GlDisclosureDropdown,
      },
      apolloProvider: createMockApollo([[getPipelineActionsQuery, queryHandler]]),
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findAllCountdowns = () => wrapper.findAllComponents(GlCountdown);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLimitMessage = () => wrapper.findByTestId('limit-reached-msg');

  it('skips calling query on mount', () => {
    createComponent();

    expect(queryHandler).not.toHaveBeenCalled();
  });

  describe('loading', () => {
    beforeEach(() => {
      createComponent();

      findDropdown().vm.$emit('shown');
    });

    it('display loading state while actions are being fetched', () => {
      expect(findAllDropdownItems().at(0).text()).toBe('Loading...');
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findAllDropdownItems()).toHaveLength(1);
    });
  });

  describe('loaded', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      createComponent();

      findDropdown().vm.$emit('shown');

      await waitForPromises();
    });

    afterEach(() => {
      mock.restore();
      confirmAction.mockReset();
    });

    it('displays dropdown with the provided actions', () => {
      expect(findAllDropdownItems()).toHaveLength(3);
    });

    it("displays a disabled action when it's not playable", () => {
      expect(findAllDropdownItems().at(0).props('item')).toMatchObject({
        extraAttrs: { disabled: true },
      });
    });

    describe('on action click', () => {
      it('makes a request and toggles the loading state', async () => {
        mock.onPost(mockPath).reply(HTTP_STATUS_OK);

        findAllDropdownItems().at(1).vm.$emit('action');

        await nextTick();

        expect(findDropdown().props('loading')).toBe(true);

        await waitForPromises();

        expect(findDropdown().props('loading')).toBe(false);
      });

      it('makes a failed request and toggles the loading state', async () => {
        mock.onPost(mockPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        findAllDropdownItems().at(1).vm.$emit('action');

        await nextTick();

        expect(findDropdown().props('loading')).toBe(true);

        await waitForPromises();

        expect(findDropdown().props('loading')).toBe(false);
        expect(createAlert).toHaveBeenCalledTimes(1);
      });
    });

    describe('tracking', () => {
      afterEach(() => {
        unmockTracking();
      });

      it('tracks manual actions click', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        findDropdown().vm.$emit('shown');

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_manual_actions', {
          label: TRACKING_CATEGORIES.table,
        });
      });
    });

    describe('scheduled jobs', () => {
      beforeEach(() => {
        jest
          .spyOn(Date, 'now')
          .mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
      });

      it('makes post request after confirming', async () => {
        mock.onPost(mockPath).reply(HTTP_STATUS_OK);

        confirmAction.mockResolvedValueOnce(true);

        findAllDropdownItems().at(2).vm.$emit('action');

        expect(confirmAction).toHaveBeenCalled();

        await waitForPromises();

        expect(mock.history.post).toHaveLength(1);
      });

      it('does not make post request if confirmation is cancelled', async () => {
        mock.onPost(mockPath).reply(HTTP_STATUS_OK);

        confirmAction.mockResolvedValueOnce(false);

        findAllDropdownItems().at(2).vm.$emit('action');

        expect(confirmAction).toHaveBeenCalled();

        await waitForPromises();

        expect(mock.history.post).toHaveLength(0);
      });

      it('displays the remaining time in the dropdown', () => {
        expect(findAllCountdowns().at(0).props('endDateString')).toBe(nodes[2].scheduledAt);
      });
    });
  });

  describe('limit message', () => {
    it('limit message does not show', async () => {
      createComponent();

      findDropdown().vm.$emit('shown');

      await waitForPromises();

      expect(findLimitMessage().exists()).toBe(false);
    });

    it('limit message does show', async () => {
      createComponent(3);

      findDropdown().vm.$emit('shown');

      await waitForPromises();

      expect(findLimitMessage().exists()).toBe(true);
    });
  });
});
