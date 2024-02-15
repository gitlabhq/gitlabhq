import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import EnvironmentsDetailPage from '~/environments/environment_details/index.vue';
import DeploymentsHistory from '~/environments/environment_details/components/deployment_history.vue';
import KubernetesOverview from '~/environments/environment_details/components/kubernetes_overview.vue';

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
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findTabByIndex = (index) => findAllTabs().at(index);
  const findDeploymentHistory = () => wrapper.findComponent(DeploymentsHistory);
  const findKubernetesOverview = () => wrapper.findComponent(KubernetesOverview);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders tabs component with the correct props', () => {
    expect(findTabs().props('syncActiveTabWithQueryParams')).toBe(true);
  });

  it('sets proper CSS class to the active tab', () => {
    expect(findTabByIndex(0).props('titleLinkClass')).toBe('gl-inset-border-b-2-theme-accent');
    expect(findTabByIndex(1).props('titleLinkClass')).toBe('');
  });

  it('updates the CSS class when the active tab changes', async () => {
    findTabs().vm.$emit('input', 1);
    await nextTick();

    expect(findTabByIndex(0).props('titleLinkClass')).toBe('');
    expect(findTabByIndex(1).props('titleLinkClass')).toBe('gl-inset-border-b-2-theme-accent');
  });

  describe('kubernetes overview tab', () => {
    it('renders correct title', () => {
      expect(findTabByIndex(0).attributes('title')).toBe('Kubernetes overview');
    });

    it('renders correct query param value', () => {
      expect(findTabByIndex(0).attributes('query-param-value')).toBe('kubernetes-overview');
    });

    it('renders kubernetes_overview component with correct props', () => {
      expect(findKubernetesOverview().props()).toEqual({
        projectFullPath,
        environmentName,
      });
    });
  });

  describe('deployment history tab', () => {
    it('renders correct title', () => {
      expect(findTabByIndex(1).attributes('title')).toBe('Deployment history');
    });

    it('renders correct query param value', () => {
      expect(findTabByIndex(1).attributes('query-param-value')).toBe('deployment-history');
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
