import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EnvironmentsDetailPage from '~/environments/environment_details/index.vue';
import DeploymentsHistory from '~/environments/environment_details/components/deployment_history.vue';

const projectFullPath = 'gitlab-group/test-project';
const environmentName = 'test-environment-name';
const after = 'after';
const before = null;

describe('~/environments/environment_details/index.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return shallowMount(EnvironmentsDetailPage, {
      propsData: {
        projectFullPath,
        environmentName,
        after,
        before,
      },
      stubs: { GlTab },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTab = () => wrapper.findComponent(GlTab);
  const findDeploymentHistory = () => wrapper.findComponent(DeploymentsHistory);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders tabs component with the correct props', () => {
    expect(findTabs().props('syncActiveTabWithQueryParams')).toBe(true);
  });

  describe('deployment history tab', () => {
    it('renders correct title', () => {
      expect(findTab().attributes('title')).toBe('Deployment history');
    });

    it('renders correct query param value', () => {
      expect(findTab().attributes('query-param-value')).toBe('deployment-history');
    });

    it('renders deployment_history component with correct props', () => {
      expect(findDeploymentHistory().props()).toEqual({
        projectFullPath,
        environmentName,
        after,
        before,
      });
    });
  });
});
