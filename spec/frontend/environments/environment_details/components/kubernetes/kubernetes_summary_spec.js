import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlTab, GlAlert } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import KubernetesSummary from '~/environments/environment_details/components/kubernetes/kubernetes_summary.vue';
import KubernetesTreeItem from '~/environments/environment_details/components/kubernetes/kubernetes_tree_item.vue';
import {
  mockKasTunnelUrl,
  fluxKustomization,
  k8sDeploymentsMock,
} from 'jest/environments/mock_data';

Vue.use(VueApollo);

describe('~/environments/environment_details/components/kubernetes/kubernetes_summary.vue', () => {
  let wrapper;

  const namespace = 'my-kubernetes-namespace';
  const configuration = {
    basePath: mockKasTunnelUrl,
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const findTab = () => wrapper.findComponent(GlTab);
  const findTreeItem = () => wrapper.findComponent(KubernetesTreeItem);
  const findRelatedDeployments = () => wrapper.findByTestId('related-deployments');
  const findAllDeploymentItems = () =>
    findRelatedDeployments().findAllComponents(KubernetesTreeItem);
  const findDeploymentItem = (at) => findAllDeploymentItems().at(at);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const k8sDeploymentsQuery = jest.fn().mockReturnValue(k8sDeploymentsMock);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sDeployments: k8sDeploymentsQuery,
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = ({
    fluxKustomizationProp = fluxKustomization,
    apolloProvider = createApolloProvider(),
  } = {}) => {
    wrapper = shallowMountExtended(KubernetesSummary, {
      propsData: {
        fluxKustomization: fluxKustomizationProp,
        configuration,
        namespace,
      },
      apolloProvider,
      stubs: { GlTab },
    });
  };

  describe('mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders summary tab', () => {
      expect(findTab().attributes('title')).toBe('Summary');
    });

    it('renders tree view title', () => {
      expect(findTab().text()).toBe('Tree view');
    });

    it('renders tree item with kustomization resource data', () => {
      expect(findTreeItem().props()).toEqual({
        kind: 'Kustomization',
        name: 'my-kustomization',
        status: 'reconciled',
      });
    });

    describe('related deployments', () => {
      it('renders a tree item for each related deployment', () => {
        expect(findAllDeploymentItems()).toHaveLength(2);
      });

      it.each([
        ['notification-controller', 0],
        ['source-controller', 1],
      ])('renders a tree item with name %s at %d', (name, index) => {
        expect(findDeploymentItem(index).props()).toEqual({ kind: 'Deployment', status: '', name });
      });
    });
  });

  describe('deployments data', () => {
    it("doesn't request k8s deployments data if the Kustomization is not present", () => {
      createWrapper({ fluxKustomizationProp: {} });

      expect(k8sDeploymentsQuery).not.toHaveBeenCalled();
    });

    describe('when Kustomization data is present', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
      });

      it('requests k8s deployments data when the Kustomization is present', () => {
        expect(k8sDeploymentsQuery).toHaveBeenCalledWith(
          {},
          expect.objectContaining({
            configuration,
            namespace,
          }),
          expect.any(Object),
          expect.any(Object),
        );
      });

      it.each([
        ['notification-controller', 'Ready', 0],
        ['source-controller', 'Pending', 1],
      ])('updates a tree item for %s with status %s at %d', (name, status, index) => {
        expect(findDeploymentItem(index).props()).toEqual({
          kind: 'Deployment',
          status,
          name,
        });
      });
    });

    it('renders alert when gets an error from the API', async () => {
      const errorMessage = 'Error from the cluster_client API';
      const createErroredApolloProvider = () => {
        const mockResolvers = {
          Query: {
            k8sDeployments: jest.fn().mockRejectedValueOnce(new Error(errorMessage)),
          },
        };

        return createMockApollo([], mockResolvers);
      };

      createWrapper({ apolloProvider: createErroredApolloProvider() });
      await waitForPromises();

      expect(findAlert().text()).toBe(errorMessage);
    });
  });
});
