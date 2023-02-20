import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentStatusLink from '~/environments/environment_details/components/deployment_status_link.vue';
import DeploymentStatusBadge from '~/environments/components/deployment_status_badge.vue';

describe('app/assets/javascripts/environments/environment_details/components/deployment_status_link.vue', () => {
  const testData = {
    webPath: 'http://example.com',
    status: 'success',
  };
  let wrapper;

  const createWrapper = (props) => {
    return mountExtended(DeploymentStatusLink, {
      propsData: props,
    });
  };

  describe('when the job link exists', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        deploymentJob: { webPath: testData.webPath },
        status: testData.status,
      });
    });

    it('should render a link with a correct href', () => {
      const jobLink = wrapper.findByTestId('deployment-status-job-link');
      expect(jobLink.exists()).toBe(true);
      expect(jobLink.attributes().href).toBe(testData.webPath);
    });

    it('should render a status badge', () => {
      const statusBadge = wrapper.findComponent(DeploymentStatusBadge);
      expect(statusBadge.exists()).toBe(true);
      expect(statusBadge.props().status).toBe(testData.status);
    });
  });

  describe('when no deployment job is provided', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        status: testData.status,
      });
    });

    it('should render a link with a correct href', () => {
      const jobLink = wrapper.findByTestId('deployment-status-job-link');
      expect(jobLink.exists()).toBe(false);
    });

    it('should render only a status badge', () => {
      const statusBadge = wrapper.findComponent(DeploymentStatusBadge);
      expect(statusBadge.exists()).toBe(true);
      expect(statusBadge.props().status).toBe(testData.status);
    });
  });
});
