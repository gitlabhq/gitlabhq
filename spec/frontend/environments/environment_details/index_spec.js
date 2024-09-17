import { GlLoadingIcon, GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { updateHistory, getParameterValues, setUrlParams } from '~/lib/utils/url_utility';
import EnvironmentsDetailPage from '~/environments/environment_details/index.vue';
import DeploymentsHistory from '~/environments/environment_details/components/deployment_history.vue';
import KubernetesOverview from '~/environments/environment_details/components/kubernetes/kubernetes_overview.vue';
import environmentClusterAgentQuery from '~/environments/graphql/queries/environment_cluster_agent.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { agent, kubernetesNamespace, fluxResourcePathMock } from '../graphql/mock_data';

const projectFullPath = 'gitlab-group/test-project';
const environmentName = 'test-environment-name';
const after = 'after';
const before = null;

jest.mock('~/lib/utils/url_utility');

describe('~/environments/environment_details/index.vue', () => {
  Vue.use(VueApollo);

  let wrapper;

  const createWrapper = (clusterAgent = agent) => {
    const defaultEnvironmentData = {
      data: {
        project: {
          id: '1',
          environment: {
            id: '1',
            clusterAgent,
            kubernetesNamespace,
            fluxResourcePath: fluxResourcePathMock,
            deploymentsDisplayCount: 3,
          },
        },
      },
    };
    const mockApollo = createMockApollo([
      [environmentClusterAgentQuery, jest.fn().mockResolvedValue(defaultEnvironmentData)],
    ]);

    return shallowMount(EnvironmentsDetailPage, {
      apolloProvider: mockApollo,
      propsData: {
        projectFullPath,
        environmentName,
        after,
        before,
      },
      stubs: { GlTab },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findTabByIndex = (index) => findAllTabs().at(index);
  const findDeploymentHistory = () => wrapper.findComponent(DeploymentsHistory);
  const findKubernetesOverview = () => wrapper.findComponent(KubernetesOverview);
  const findTabBadge = () => wrapper.findComponent(GlBadge);

  describe('loading state', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it("doesn't render tabs", () => {
      expect(findTabs().exists()).toBe(false);
    });

    it('hides loading indicator when the data is loaded', async () => {
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('tabs', () => {
    beforeEach(async () => {
      wrapper = createWrapper();
      await waitForPromises();
    });

    it('renders tabs component with the correct prop', () => {
      expect(findTabs().props('syncActiveTabWithQueryParams')).toBe(true);
    });
  });

  describe('kubernetes overview tab', () => {
    beforeEach(async () => {
      wrapper = createWrapper();
      await waitForPromises();
    });
    it('renders correct title', () => {
      expect(findTabByIndex(0).attributes('title')).toBe('Kubernetes overview');
    });

    it('renders correct query param value', () => {
      expect(findTabByIndex(0).attributes('query-param-value')).toBe('kubernetes-overview');
    });

    it('renders kubernetes_overview component with correct props', () => {
      expect(findKubernetesOverview().props()).toEqual({
        environmentName,
        environmentId: '1',
        clusterAgent: agent,
        kubernetesNamespace,
        fluxResourcePath: fluxResourcePathMock,
      });
    });
  });

  describe('deployment history tab', () => {
    beforeEach(async () => {
      wrapper = createWrapper();
      await waitForPromises();
    });

    it('renders correct title', () => {
      expect(findTabByIndex(1).text()).toContain('Deployment history');
    });

    it('renders a badge with the correct number of deployments', () => {
      expect(findTabBadge().text()).toBe('3');
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

  describe('when there is cluster agent data', () => {
    beforeEach(async () => {
      wrapper = createWrapper();
      await waitForPromises();
    });

    it('shows the Kubernetes overview tab as active', () => {
      expect(findTabs().props('value')).toBe(0);
    });
  });

  describe('when there is no cluster agent data', () => {
    it('navigates to the Deployments history tab if the tab was not specified in the URL', async () => {
      getParameterValues.mockReturnValue([]);
      wrapper = createWrapper(null);
      await waitForPromises();

      expect(setUrlParams).toHaveBeenCalledWith({ tab: 'deployment-history' });
      expect(updateHistory).toHaveBeenCalled();
    });

    it("doesn't navigate to the Deployments history tab if the tab was specified in the URL", async () => {
      getParameterValues.mockReturnValue([{ tab: 'kubernetes-overview' }]);
      wrapper = createWrapper(null);
      await waitForPromises();

      expect(setUrlParams).not.toHaveBeenCalled();
      expect(updateHistory).not.toHaveBeenCalled();
    });
  });
});
