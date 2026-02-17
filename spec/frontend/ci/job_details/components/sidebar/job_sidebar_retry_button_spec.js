import MockAdapter from 'axios-mock-adapter';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import JobsSidebarRetryButton from '~/ci/job_details/components/sidebar/job_sidebar_retry_button.vue';
import createStore from '~/ci/job_details/store';
import job from 'jest/ci/jobs_mock_data';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

const defaultProvide = {
  canSetPipelineVariables: true,
};

describe('Job Sidebar Retry Button', () => {
  let store;
  let wrapper;

  const forwardDeploymentFailure = 'forward_deployment_failure';
  const findRetryButton = () => wrapper.findByTestId('retry-job-button');
  const findRetryLink = () => wrapper.findByTestId('retry-job-link');
  const findManualRetryButton = () => wrapper.findByTestId('manual-run-again-btn');
  const findManualRunEditButton = () => wrapper.findByTestId('manual-run-edit-btn');
  const findActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const createWrapper = ({ mountFn = shallowMountExtended, props = {}, provide = {} } = {}) => {
    store = createStore();
    wrapper = mountFn(JobsSidebarRetryButton, {
      propsData: {
        href: job.retry_path,
        isManualJob: false,
        modalId: 'modal-id',
        jobName: job.name,
        confirmationMessage: null,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      store,
    });
  };

  const createWrapperWithConfirmation = () => {
    createWrapper({
      mountFn: mountExtended,
      props: {
        isManualJob: true,
        confirmationMessage: 'Are you sure?',
      },
    });
  };

  it.each([
    [null, false, true],
    ['unmet_prerequisites', false, true],
    [forwardDeploymentFailure, true, false],
  ])(
    'when error is: %s, should render button: %s | should render link: %s',
    async (failureReason, buttonExists, linkExists) => {
      createWrapper();
      await store.dispatch('receiveJobSuccess', { ...job, failure_reason: failureReason });

      expect(findRetryButton().exists()).toBe(buttonExists);
      expect(findRetryLink().exists()).toBe(linkExists);
    },
  );

  describe('Button', () => {
    it('should have the correct configuration', async () => {
      createWrapper();

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
      createWrapper();

      expect(findRetryLink().attributes()).toMatchObject({
        'data-method': 'post',
        href: job.retry_path,
        icon: 'retry',
      });
    });
  });

  describe('confirmationMessage', () => {
    it('should not render confirmation modal if confirmation message is null', () => {
      createWrapper();
      findRetryLink().trigger('click');
      expect(confirmAction).not.toHaveBeenCalled();
    });

    it('should render confirmation modal if confirmation message is presented', async () => {
      createWrapperWithConfirmation();

      await findManualRetryButton().trigger('click');

      expect(confirmAction).toHaveBeenCalledWith(
        null,
        expect.objectContaining({
          primaryBtnText: `Yes, run ${job.name}`,
          title: `Are you sure you want to run ${job.name}?`,
          modalHtmlMessage: expect.stringContaining('Are you sure?'),
        }),
      );
    });

    it('emit `update-variables-clicked` when update button is clicked', async () => {
      createWrapperWithConfirmation();

      await findManualRunEditButton().vm.$emit('action');
      expect(wrapper.emitted('update-variables-clicked')).toEqual([[]]);
    });

    it('should retry job if click on confirm', async () => {
      const mock = new MockAdapter(axios);
      createWrapperWithConfirmation();
      confirmAction.mockResolvedValueOnce(true);

      await findManualRetryButton().trigger('click');
      await waitForPromises();

      expect(mock.history.post[0].url).toBe(job.retry_path);
    });
  });

  describe('retry with modified values dropdown visibility', () => {
    it('is rendered with correct text and attributes', async () => {
      createWrapper({ props: { isManualJob: true } });
      await waitForPromises();
      expect(findActionsDropdown().attributes('aria-label')).toBe('Retry job with modified value');
      expect(findManualRunEditButton().text()).toBe('Retry job with modified value');
    });

    it.each`
      isManualJob | ciJobInputsFlag | canSetPipelineVariables | shouldShowDropdown | description
      ${true}     | ${false}        | ${true}                 | ${true}            | ${'shows dropdown for manual job with pipeline variables permission'}
      ${true}     | ${false}        | ${false}                | ${false}           | ${'does not show dropdown for manual job without pipeline variables permission'}
      ${true}     | ${true}         | ${true}                 | ${true}            | ${'shows dropdown for manual job with feature flag enabled'}
      ${true}     | ${true}         | ${false}                | ${true}            | ${'shows dropdown for manual job with feature flag enabled (ignores permission)'}
      ${false}    | ${true}         | ${true}                 | ${true}            | ${'shows dropdown for retryable job with feature flag enabled'}
      ${false}    | ${false}        | ${true}                 | ${false}           | ${'does not show retryable job without feature flag'}
    `(
      '$description',
      async ({ isManualJob, ciJobInputsFlag, canSetPipelineVariables, shouldShowDropdown }) => {
        createWrapper({
          props: { isManualJob },
          provide: {
            glFeatures: { ciJobInputs: ciJobInputsFlag },
            canSetPipelineVariables,
          },
        });
        await waitForPromises();

        expect(findActionsDropdown().exists()).toBe(shouldShowDropdown);
      },
    );
  });
});
