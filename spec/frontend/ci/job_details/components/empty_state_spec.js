import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/ci/job_details/components/empty_state.vue';
import ManualJobForm from '~/ci/job_details/components/manual_job_form.vue';
import { mockId } from '../mock_data';

describe('Empty State', () => {
  let wrapper;

  const defaultProps = {
    illustrationPath: 'illustrations/empty-state/empty-job-pending-md.svg',
    jobId: mockId,
    jobName: 'My job',
    title: 'This job has not started yet',
    playable: false,
    isRetryable: true,
  };

  const createWrapper = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(EmptyState, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const content = 'This job is in pending state and is waiting to be picked by a runner';

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findEmptyStateImage = () => findEmptyState().props('svgPath');
  const findTitle = () => findEmptyState().props('title');
  const findContent = () => wrapper.findByTestId('job-empty-state-content');
  const findAction = () => wrapper.findByTestId('job-empty-state-action');
  const findManualVarsForm = () => wrapper.findComponent(ManualJobForm);

  describe('renders image and title', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders empty state image', () => {
      expect(findEmptyStateImage()).toBe(defaultProps.illustrationPath);
    });

    it('renders provided title', () => {
      expect(findTitle()).toBe(defaultProps.title);
    });
  });

  describe('with content', () => {
    beforeEach(() => {
      createWrapper({ props: { content } });
    });

    it('renders content', () => {
      expect(findContent().text().trim()).toBe(content);
    });
  });

  describe('without content', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render content', () => {
      expect(findContent().exists()).toBe(false);
    });
  });

  describe('with action', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          action: {
            path: 'runner',
            button_title: 'Check runner',
            method: 'post',
          },
        },
      });
    });

    it('renders action', () => {
      expect(findAction().attributes('href')).toBe('runner');
    });
  });

  describe('without action', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          action: null,
        },
      });
    });

    it('does not render action', () => {
      expect(findAction().exists()).toBe(false);
    });

    it('does not render manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(false);
    });
  });

  describe('with playable action and not scheduled job', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          content,
          playable: true,
          scheduled: false,
          action: {
            path: 'runner',
            button_title: 'Check runner',
            method: 'post',
          },
        },
      });
    });

    it('renders manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(true);
    });

    it('does not render the empty state action', () => {
      expect(findAction().exists()).toBe(false);
    });
  });

  describe('with playable action and scheduled job', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          playable: true,
          scheduled: true,
          content,
        },
      });
    });

    it('does not render manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(false);
    });
  });

  describe('when user is not allowed to retry the pipeline', () => {
    beforeEach(() => {
      createWrapper({
        props: { content, isRetryable: false },
      });
    });

    it('does not render manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(false);
    });

    it('does not render additional text for pipeline variables when it is not a retryable job', () => {
      expect(findContent().text()).not.toContain(
        'You can add CI/CD variables below for last-minute configuration changes before starting the job.',
      );
    });
  });
});
