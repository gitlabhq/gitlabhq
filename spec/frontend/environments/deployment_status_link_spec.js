import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
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

  const findStatusBadge = () => wrapper.findComponent(DeploymentStatusBadge);

  describe('when the deployment has a web path', () => {
    let webPath;

    beforeEach(() => {
      webPath = `${testData.webPath}/deployments`;
      wrapper = createWrapper({
        deployment: { webPath },
        deploymentJob: { webPath: testData.webPath },
        status: testData.status,
      });
    });

    it('should render a link with a correct href', () => {
      const jobLink = findStatusBadge();

      expect(jobLink.exists()).toBe(true);
      expect(jobLink.attributes().href).toBe(webPath);
      expect(jobLink.props().status).toBe(testData.status);
    });
  });

  describe('when the job link exists', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        deploymentJob: { webPath: testData.webPath },
        status: testData.status,
      });
    });

    it('should render a link with a correct href', () => {
      const jobLink = findStatusBadge();

      expect(jobLink.exists()).toBe(true);
      expect(jobLink.attributes().href).toBe(testData.webPath);
      expect(jobLink.props().status).toBe(testData.status);
    });
  });

  describe('when the job link is an old property', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        deploymentJob: { buildPath: testData.webPath },
        status: testData.status,
      });
    });

    it('should render a link with a correct href', () => {
      const jobLink = findStatusBadge();

      expect(jobLink.exists()).toBe(true);
      expect(jobLink.attributes().href).toBe(testData.webPath);
      expect(jobLink.props().status).toBe(testData.status);
    });
  });

  describe('when no deployment job is provided', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        status: testData.status,
      });
    });

    it('should render only a status badge', () => {
      const statusBadge = findStatusBadge();

      expect(statusBadge.exists()).toBe(true);
      expect(statusBadge.props().status).toBe(testData.status);
      expect(statusBadge.props().href).toBe('');
    });
  });
});
