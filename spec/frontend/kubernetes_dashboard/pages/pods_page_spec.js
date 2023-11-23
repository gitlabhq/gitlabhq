import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import PodsPage from '~/kubernetes_dashboard/pages/pods_page.vue';
import WorkloadStats from '~/kubernetes_dashboard/components/workload_stats.vue';
import { k8sPodsMock, mockPodStats } from '../graphql/mock_data';

Vue.use(VueApollo);

describe('Kubernetes dashboard pods page', () => {
  let wrapper;

  const configuration = {
    basePath: 'kas/tunnel/url',
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkloadStats = () => wrapper.findComponent(WorkloadStats);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sPods: jest.fn().mockReturnValue(k8sPodsMock),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (apolloProvider = createApolloProvider()) => {
    wrapper = shallowMount(PodsPage, {
      provide: { configuration },
      apolloProvider,
    });
  };

  describe('mounted', () => {
    it('shows the loading icon', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('hides the loading icon when the list of pods loaded', async () => {
      createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when gets pods data', () => {
    it('renders stats', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadStats().exists()).toBe(true);
    });

    it('provides correct data for stats', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadStats().props('stats')).toEqual(mockPodStats);
    });
  });

  describe('when gets an error from the cluster_client API', () => {
    const error = new Error('Error from the cluster_client API');
    const createErroredApolloProvider = () => {
      const mockResolvers = {
        Query: {
          k8sPods: jest.fn().mockRejectedValueOnce(error),
        },
      };

      return createMockApollo([], mockResolvers);
    };

    beforeEach(async () => {
      createWrapper(createErroredApolloProvider());
      await waitForPromises();
    });

    it("doesn't show pods stats", () => {
      expect(findWorkloadStats().exists()).toBe(false);
    });

    it('renders an alert with the error message', () => {
      expect(findAlert().text()).toBe(error.message);
    });
  });
});
