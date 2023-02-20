import DeploymentActions from '~/environments/environment_details/components/deployment_actions.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ActionsComponent from '~/environments/components/environment_actions.vue';

describe('~/environments/environment_details/components/deployment_actions.vue', () => {
  let wrapper;

  const actionsData = [
    {
      playable: true,
      playPath: 'http://www.example.com/play',
      name: 'deploy-staging',
      scheduledAt: '2023-01-18T08:50:08.390Z',
    },
  ];

  const createWrapper = ({ actions }) => {
    return mountExtended(DeploymentActions, {
      propsData: {
        actions,
      },
    });
  };

  describe('when there is no actions provided', () => {
    beforeEach(() => {
      wrapper = createWrapper({ actions: [] });
    });

    it('should not render actions component', () => {
      const actionsComponent = wrapper.findComponent(ActionsComponent);
      expect(actionsComponent.exists()).toBe(false);
    });
  });

  describe('when there are actions provided', () => {
    beforeEach(() => {
      wrapper = createWrapper({ actions: actionsData });
    });

    it('should render actions component', () => {
      const actionsComponent = wrapper.findComponent(ActionsComponent);
      expect(actionsComponent.exists()).toBe(true);
      expect(actionsComponent.props().actions).toBe(actionsData);
    });
  });
});
