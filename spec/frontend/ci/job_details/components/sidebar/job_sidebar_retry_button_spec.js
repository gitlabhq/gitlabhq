import MockAdapter from 'axios-mock-adapter';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import JobsSidebarRetryButton from '~/ci/job_details/components/sidebar/job_sidebar_retry_button.vue';
import createStore from '~/ci/job_details/store';
import job from 'jest/ci/jobs_mock_data';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

describe('Job Sidebar Retry Button', () => {
  let store;
  let wrapper;

  const forwardDeploymentFailure = 'forward_deployment_failure';
  const findRetryButton = () => wrapper.findByTestId('retry-job-button');
  const findRetryLink = () => wrapper.findByTestId('retry-job-link');

  const createWrapper = ({ props = {} } = {}) => {
    store = createStore();
    wrapper = shallowMountExtended(JobsSidebarRetryButton, {
      propsData: {
        href: job.retry_path,
        isManualJob: false,
        modalId: 'modal-id',
        jobName: job.name,
        confirmationMessage: null,
        ...props,
      },
      store,
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it.each([
    [null, false, true],
    ['unmet_prerequisites', false, true],
    [forwardDeploymentFailure, true, false],
  ])(
    'when error is: %s, should render button: %s | should render link: %s',
    async (failureReason, buttonExists, linkExists) => {
      await store.dispatch('receiveJobSuccess', { ...job, failure_reason: failureReason });

      expect(findRetryButton().exists()).toBe(buttonExists);
      expect(findRetryLink().exists()).toBe(linkExists);
    },
  );

  describe('Button', () => {
    it('should have the correct configuration', async () => {
      await store.dispatch('receiveJobSuccess', { failure_reason: forwardDeploymentFailure });
      expect(findRetryButton().attributes()).toMatchObject({
        category: 'primary',
        variant: 'confirm',
        icon: 'retry',
      });
    });
  });

  describe('Link', () => {
    it('should have the correct configuration', () => {
      expect(findRetryLink().attributes()).toMatchObject({
        'data-method': 'post',
        href: job.retry_path,
        icon: 'retry',
      });
    });
  });

  describe('confirmationMessage', () => {
    const createWrapperWithConfirmation = () => {
      wrapper = mountExtended(JobsSidebarRetryButton, {
        propsData: {
          href: job.retry_path,
          modalId: 'modal-id',
          jobName: job.name,
          isManualJob: true,
          confirmationMessage: 'Are you sure?',
        },
        store,
      });
    };

    it('should not render confirmation modal if confirmation message is null', () => {
      findRetryLink().trigger('click');
      expect(confirmAction).not.toHaveBeenCalled();
    });

    it('should render confirmation modal if confirmation message is presented', async () => {
      createWrapperWithConfirmation();

      const itemElements = wrapper.findAll('.gl-new-dropdown-item-content');
      await itemElements.at(0).trigger('click');

      expect(confirmAction).toHaveBeenCalledWith(
        null,
        expect.objectContaining({
          primaryBtnText: `Yes, run ${job.name}`,
          title: `Are you sure you want to run ${job.name}?`,
          modalHtmlMessage: expect.stringContaining('Are you sure?'),
        }),
      );
    });

    it('should retry job if click on confirm', async () => {
      const mock = new MockAdapter(axios);
      createWrapperWithConfirmation();
      confirmAction.mockResolvedValueOnce(true);

      const itemElements = wrapper.findAll('.gl-new-dropdown-item-content');
      await itemElements.at(0).trigger('click');
      await waitForPromises();

      expect(mock.history.post[0].url).toBe(job.retry_path);
    });
  });
});
