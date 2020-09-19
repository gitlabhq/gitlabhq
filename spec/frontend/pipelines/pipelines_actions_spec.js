import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import { GlButton } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import PipelinesActions from '~/pipelines/components/pipelines_list/pipelines_actions.vue';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

describe('Pipelines Actions dropdown', () => {
  let wrapper;
  let mock;

  const createComponent = (actions = []) => {
    wrapper = shallowMount(PipelinesActions, {
      propsData: {
        actions,
      },
    });
  };

  const findAllDropdownItems = () => wrapper.findAll(GlButton);
  const findAllCountdowns = () => wrapper.findAll(GlCountdown);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
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
      createComponent(mockActions);
    });

    it('renders a dropdown with the provided actions', () => {
      expect(findAllDropdownItems()).toHaveLength(mockActions.length);
    });

    it("renders a disabled action when it's not playable", () => {
      expect(
        findAllDropdownItems()
          .at(1)
          .attributes('disabled'),
      ).toBe('true');
    });

    describe('on click', () => {
      it('makes a request and toggles the loading state', () => {
        mock.onPost(mockActions.path).reply(200);

        wrapper.find(GlButton).vm.$emit('click');

        expect(wrapper.vm.isLoading).toBe(true);

        return waitForPromises().then(() => {
          expect(wrapper.vm.isLoading).toBe(false);
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
      createComponent([scheduledJobAction, expiredJobAction]);
    });

    it('makes post request after confirming', () => {
      mock.onPost(scheduledJobAction.path).reply(200);
      jest.spyOn(window, 'confirm').mockReturnValue(true);

      findAllDropdownItems()
        .at(0)
        .vm.$emit('click');

      expect(window.confirm).toHaveBeenCalled();

      return waitForPromises().then(() => {
        expect(mock.history.post.length).toBe(1);
      });
    });

    it('does not make post request if confirmation is cancelled', () => {
      mock.onPost(scheduledJobAction.path).reply(200);
      jest.spyOn(window, 'confirm').mockReturnValue(false);

      findAllDropdownItems()
        .at(0)
        .vm.$emit('click');

      expect(window.confirm).toHaveBeenCalled();
      expect(mock.history.post.length).toBe(0);
    });

    it('displays the remaining time in the dropdown', () => {
      expect(
        findAllCountdowns()
          .at(0)
          .props('endDateString'),
      ).toBe(scheduledJobAction.scheduled_at);
    });

    it('displays 00:00:00 for expired jobs in the dropdown', () => {
      expect(
        findAllCountdowns()
          .at(1)
          .props('endDateString'),
      ).toBe(expiredJobAction.scheduled_at);
    });
  });
});
