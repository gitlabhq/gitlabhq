import { GlLink, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JobRetryForwardDeploymentModal from '~/ci/job_details/components/sidebar/job_retry_forward_deployment_modal.vue';
import createStore from '~/ci/job_details/store';
import job from 'jest/ci/jobs_mock_data';

describe('Job Retry Forward Deployment Modal', () => {
  let store;
  let wrapper;

  const retryOutdatedJobDocsUrl = 'url-to-docs';
  const findLink = () => wrapper.findComponent(GlLink);
  const findModal = () => wrapper.findComponent(GlModal);

  const createWrapper = ({ props = {}, provide = {}, stubs = {} } = {}) => {
    store = createStore();
    wrapper = shallowMount(JobRetryForwardDeploymentModal, {
      propsData: {
        modalId: 'modal-id',
        href: job.retry_path,
        ...props,
      },
      provide,
      store,
      stubs,
    });
  };

  beforeEach(createWrapper);

  describe('Modal configuration', () => {
    it('should display the correct messages', () => {
      const modal = findModal();
      expect(modal.attributes('title')).toMatch('Are you sure you want to retry this job?');
      expect(modal.text()).toMatch(
        "You're about to retry a job that failed because it attempted to deploy code that is older than the latest deployment. Retrying this job could result in overwriting the environment with the older source code.",
      );
      expect(modal.text()).toMatch('Are you sure you want to proceed?');
    });
  });

  describe('Modal docs help link', () => {
    it('should not display an info link when none is provided', () => {
      createWrapper();

      expect(findLink().exists()).toBe(false);
    });

    it('should display an info link when one is provided', () => {
      createWrapper({ provide: { retryOutdatedJobDocsUrl } });

      expect(findLink().attributes('href')).toBe(retryOutdatedJobDocsUrl);
      expect(findLink().text()).toMatch('More information');
    });
  });

  describe('Modal actions', () => {
    beforeEach(createWrapper);

    it('should correctly configure the primary action', () => {
      expect(findModal().props('actionPrimary').attributes).toMatchObject({
        'data-method': 'post',
        href: job.retry_path,
        variant: 'danger',
      });
    });
  });
});
