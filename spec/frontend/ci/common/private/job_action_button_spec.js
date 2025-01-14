import { GlButton, GlIcon } from '@gitlab/ui';

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';

import JobActionButton, { i18n } from '~/ci/common/private/job_action_button.vue';

import cancelJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_cancel.mutation.graphql';
import playJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_play.mutation.graphql';
import retryJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_retry.mutation.graphql';
import unscheduleJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_unschedule.mutation.graphql';
import {
  mockJobActions,
  mockJobCancelResponse,
  mockJobPlayResponse,
  mockJobRetryResponse,
  mockJobUnscheduleResponse,
} from '../../pipeline_mini_graph/mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('JobActionButton', () => {
  let wrapper;

  const jobAction = mockJobActions[0];

  const defaultProps = {
    jobAction,
    jobId: 'gid://gitlab/Ci::Build/5521',
    jobName: 'test_job',
  };

  const createComponent = ({ handlers = [], props = {} } = {}) => {
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(JobActionButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const cancelMutationHandler = jest.fn().mockResolvedValue(mockJobCancelResponse);
  const playMutationHandler = jest.fn().mockResolvedValue(mockJobPlayResponse);
  const retryMutationHandler = jest.fn().mockResolvedValue(mockJobRetryResponse);
  const unscheduleMutationHandler = jest.fn().mockResolvedValue(mockJobUnscheduleResponse);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const findActionButton = () => wrapper.findComponent(GlButton);
  const findActionIcon = () => wrapper.findComponent(GlIcon);

  const clickActionButton = async () => {
    const event = { preventDefault: jest.fn() };
    findActionButton().vm.$emit('click', event);
    await waitForPromises();
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the action icon', () => {
      expect(findActionIcon().exists()).toBe(true);
    });

    it('renders the tooltip', () => {
      expect(findActionButton().exists()).toBe(true);
    });

    describe('job action button', () => {
      describe.each`
        action          | icon          | tooltip         | mockIndex
        ${'cancel'}     | ${'cancel'}   | ${'Cancel'}     | ${0}
        ${'run'}        | ${'play'}     | ${'Run'}        | ${1}
        ${'retry'}      | ${'retry'}    | ${'Run again'}  | ${2}
        ${'unschedule'} | ${'time-out'} | ${'Unschedule'} | ${3}
      `('$action action', ({ icon, mockIndex, tooltip }) => {
        beforeEach(() => {
          createComponent({ props: { jobAction: mockJobActions[mockIndex] } });
        });

        it('displays the correct icon', () => {
          expect(findActionIcon().exists()).toBe(true);
          expect(findActionIcon().props('name')).toBe(icon);
        });

        it('displays the correct tooltip', () => {
          expect(findActionButton().exists()).toBe(true);
          expect(findActionButton().attributes('title')).toBe(tooltip);
        });
      });
    });

    describe('mutations', () => {
      describe.each`
        action          | mockIndex | mutation                 | handler                      | errorMessage
        ${'cancel'}     | ${0}      | ${cancelJobMutation}     | ${cancelMutationHandler}     | ${i18n.errors.cancelJob}
        ${'run'}        | ${1}      | ${playJobMutation}       | ${playMutationHandler}       | ${i18n.errors.playJob}
        ${'retry'}      | ${2}      | ${retryJobMutation}      | ${retryMutationHandler}      | ${i18n.errors.retryJob}
        ${'unschedule'} | ${3}      | ${unscheduleJobMutation} | ${unscheduleMutationHandler} | ${i18n.errors.unscheduleJob}
      `('$action action', ({ mockIndex, mutation, handler, errorMessage }) => {
        it('calls the correct mutation on button click', async () => {
          await createComponent({
            handlers: [[mutation, handler]],
            props: { jobAction: mockJobActions[mockIndex] },
          });
          await clickActionButton();

          expect(handler).toHaveBeenCalledWith({ id: defaultProps.jobId });
          expect(wrapper.emitted('jobActionExecuted')).toHaveLength(1);
        });

        it('displays the appropriate error message if mutation is not successful', async () => {
          await createComponent({
            handlers: [[mutation, failedHandler]],
            props: { jobAction: mockJobActions[mockIndex] },
          });
          await clickActionButton();

          expect(createAlert).toHaveBeenCalledWith({ message: errorMessage });
        });
      });
    });

    it('passes correct props', () => {
      expect(findActionButton().props()).toStrictEqual({
        block: false,
        buttonTextClasses: '',
        category: 'primary',
        disabled: false,
        icon: '',
        isUnsafeLink: false,
        label: false,
        loading: false,
        selected: false,
        size: 'small',
        target: null,
        variant: 'default',
      });
    });
  });
});
