import { mountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import Deployment from '~/environments/components/deployment.vue';
import DeploymentStatusBadge from '~/environments/components/deployment_status_badge.vue';
import { resolvedEnvironment } from './graphql/mock_data';

describe('~/environments/components/deployment.vue', () => {
  const deployment = resolvedEnvironment.lastDeployment;
  let wrapper;

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(Deployment, {
      propsData: {
        deployment,
        ...propsData,
      },
    });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('status', () => {
    it('should pass the deployable status to the badge', () => {
      wrapper = createWrapper();
      expect(wrapper.findComponent(DeploymentStatusBadge).props('status')).toBe(deployment.status);
    });
  });

  describe('latest', () => {
    it('should show a badge if the deployment is latest', () => {
      wrapper = createWrapper({ propsData: { latest: true } });

      const badge = wrapper.findByText(s__('Deployment|Latest Deployed'));

      expect(badge.exists()).toBe(true);
    });

    it('should not show a badge if the deployment is not latest', () => {
      wrapper = createWrapper();

      const badge = wrapper.findByText(s__('Deployment|Latest Deployed'));

      expect(badge.exists()).toBe(false);
    });
  });

  describe('iid', () => {
    const findIid = () => wrapper.findByTitle(s__('Deployment|Deployment ID'));
    const findDeploymentIcon = () => wrapper.findComponent({ ref: 'deployment-iid-icon' });

    describe('is present', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should show the iid', () => {
        const iid = findIid();
        expect(iid.exists()).toBe(true);
      });

      it('should show an icon for the iid', () => {
        const deploymentIcon = findDeploymentIcon();
        expect(deploymentIcon.props('name')).toBe('deployments');
      });
    });

    describe('is not present', () => {
      beforeEach(() => {
        wrapper = createWrapper({ propsData: { deployment: { ...deployment, iid: '' } } });
      });

      it('should not show the iid', () => {
        const iid = findIid();
        expect(iid.exists()).toBe(false);
      });

      it('should not show an icon for the iid', () => {
        const deploymentIcon = findDeploymentIcon();
        expect(deploymentIcon.exists()).toBe(false);
      });
    });
  });
});
