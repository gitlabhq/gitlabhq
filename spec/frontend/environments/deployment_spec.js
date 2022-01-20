import { mountExtended } from 'helpers/vue_test_utils_helper';
import Deployment from '~/environments/components/deployment.vue';
import DeploymentStatusBadge from '~/environments/components/deployment_status_badge.vue';
import { resolvedEnvironment } from './graphql/mock_data';

describe('~/environments/components/deployment.vue', () => {
  let wrapper;

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(Deployment, {
      propsData: {
        deployment: resolvedEnvironment.lastDeployment,
        ...propsData,
      },
    });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('status', () => {
    it('should pass the deployable status to the badge', () => {
      wrapper = createWrapper();
      expect(wrapper.findComponent(DeploymentStatusBadge).props('status')).toBe(
        resolvedEnvironment.lastDeployment.status,
      );
    });
  });
});
