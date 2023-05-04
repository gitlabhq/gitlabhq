import { GlLink, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JobRetryForwardDeploymentModal from '~/jobs/components/job/sidebar/job_retry_forward_deployment_modal.vue';
import { JOB_RETRY_FORWARD_DEPLOYMENT_MODAL } from '~/jobs/constants';
import createStore from '~/jobs/store';
import job from '../../mock_data';

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
      expect(modal.attributes('title')).toMatch(JOB_RETRY_FORWARD_DEPLOYMENT_MODAL.title);
      expect(modal.text()).toMatch(JOB_RETRY_FORWARD_DEPLOYMENT_MODAL.info);
      expect(modal.text()).toMatch(JOB_RETRY_FORWARD_DEPLOYMENT_MODAL.areYouSure);
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
      expect(findLink().text()).toMatch(JOB_RETRY_FORWARD_DEPLOYMENT_MODAL.moreInfo);
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
