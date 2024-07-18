import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import mockPipelineActionsQueryResponse from 'test_fixtures/graphql/pipelines/get_pipeline_actions.query.graphql.json';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import PipelinesManualActions from '~/ci/pipelines_page/components/pipelines_manual_actions.vue';
import getPipelineActionsQuery from '~/ci/pipelines_page/graphql/queries/get_pipeline_actions.query.graphql';
import jobPlayMutation from '~/ci/jobs_page/graphql/mutations/job_play.mutation.graphql';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('Pipeline manual actions', () => {
  let wrapper;

  const queryHandler = jest.fn().mockResolvedValue(mockPipelineActionsQueryResponse);
  const jobPlayMutationHandler = jest.fn();

  const {
    data: {
      project: {
        pipeline: {
          jobs: { nodes },
        },
      },
    },
  } = mockPipelineActionsQueryResponse;

  const createComponent = (limit = 50) => {
    const apolloProvider = createMockApollo([
      [getPipelineActionsQuery, queryHandler],
      [jobPlayMutation, jobPlayMutationHandler],
    ]);

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
      apolloProvider,
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
      createComponent();

      findDropdown().vm.$emit('shown');

      await waitForPromises();
    });

    afterEach(() => {
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
        findAllDropdownItems().at(1).vm.$emit('action');

        await nextTick();

        expect(findDropdown().props('loading')).toBe(true);

        await waitForPromises();

        expect(findDropdown().props('loading')).toBe(false);
        expect(jobPlayMutationHandler).toHaveBeenCalledTimes(1);
      });

      it('makes a failed request and toggles the loading state', async () => {
        jobPlayMutationHandler.mockRejectedValueOnce(new Error('GraphQL error'));

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

      it('makes calls GraphQl mutation after confirming', async () => {
        confirmAction.mockResolvedValueOnce(true);

        findAllDropdownItems().at(2).vm.$emit('action');

        expect(confirmAction).toHaveBeenCalled();

        await waitForPromises();

        expect(jobPlayMutationHandler).toHaveBeenCalledTimes(1);
      });

      it('does not call GraphQl mutation if confirmation is cancelled', async () => {
        confirmAction.mockResolvedValueOnce(false);

        findAllDropdownItems().at(2).vm.$emit('action');

        expect(confirmAction).toHaveBeenCalled();

        await waitForPromises();

        expect(jobPlayMutationHandler).not.toHaveBeenCalled();
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
