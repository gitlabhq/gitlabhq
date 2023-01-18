import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import PipelinesManualActions from '~/pipelines/components/pipelines_list/pipelines_manual_actions.vue';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import { TRACKING_CATEGORIES } from '~/pipelines/constants';

jest.mock('~/flash');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('Pipelines Actions dropdown', () => {
  let wrapper;
  let mock;

  const createComponent = (props, mountFn = shallowMount) => {
    wrapper = mountFn(PipelinesManualActions, {
      propsData: {
        ...props,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findAllCountdowns = () => wrapper.findAllComponents(GlCountdown);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
    confirmAction.mockReset();
  });

  describe('manual actions', () => {
    const mockActions = [
      {
        name: 'stop_review',
        path: `${TEST_HOST}/root/review-app/builds/1893/play`,
      },
      {
        name: 'foo',
        path: `${TEST_HOST}/disabled/pipeline/action`,
        playable: false,
      },
    ];

    beforeEach(() => {
      createComponent({ actions: mockActions });
    });

    it('renders a dropdown with the provided actions', () => {
      expect(findAllDropdownItems()).toHaveLength(mockActions.length);
    });

    it("renders a disabled action when it's not playable", () => {
      expect(findAllDropdownItems().at(1).attributes('disabled')).toBe('true');
    });

    describe('on click', () => {
      it('makes a request and toggles the loading state', async () => {
        mock.onPost(mockActions.path).reply(HTTP_STATUS_OK);

        findAllDropdownItems().at(0).vm.$emit('click');

        await nextTick();
        expect(findDropdown().props('loading')).toBe(true);

        await waitForPromises();
        expect(findDropdown().props('loading')).toBe(false);
      });

      it('makes a failed request and toggles the loading state', async () => {
        mock.onPost(mockActions.path).reply(500);

        findAllDropdownItems().at(0).vm.$emit('click');

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
  });

  describe('scheduled jobs', () => {
    const scheduledJobAction = {
      name: 'scheduled action',
      path: `${TEST_HOST}/scheduled/job/action`,
      playable: true,
      scheduled_at: '2063-04-05T00:42:00Z',
    };
    const expiredJobAction = {
      name: 'expired action',
      path: `${TEST_HOST}/expired/job/action`,
      playable: true,
      scheduled_at: '2018-10-05T08:23:00Z',
    };

    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
      createComponent({ actions: [scheduledJobAction, expiredJobAction] });
    });

    it('makes post request after confirming', async () => {
      mock.onPost(scheduledJobAction.path).reply(HTTP_STATUS_OK);
      confirmAction.mockResolvedValueOnce(true);

      findAllDropdownItems().at(0).vm.$emit('click');

      expect(confirmAction).toHaveBeenCalled();

      await waitForPromises();

      expect(mock.history.post).toHaveLength(1);
    });

    it('does not make post request if confirmation is cancelled', async () => {
      mock.onPost(scheduledJobAction.path).reply(HTTP_STATUS_OK);
      confirmAction.mockResolvedValueOnce(false);

      findAllDropdownItems().at(0).vm.$emit('click');

      expect(confirmAction).toHaveBeenCalled();

      await waitForPromises();

      expect(mock.history.post).toHaveLength(0);
    });

    it('displays the remaining time in the dropdown', () => {
      expect(findAllCountdowns().at(0).props('endDateString')).toBe(
        scheduledJobAction.scheduled_at,
      );
    });

    it('displays 00:00:00 for expired jobs in the dropdown', () => {
      expect(findAllCountdowns().at(1).props('endDateString')).toBe(expiredJobAction.scheduled_at);
    });
  });
});
