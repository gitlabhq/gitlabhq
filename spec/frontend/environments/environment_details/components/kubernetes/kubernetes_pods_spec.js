import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTab, GlSearchBoxByType, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesPods from '~/environments/environment_details/components/kubernetes/kubernetes_pods.vue';
import WorkloadStats from '~/kubernetes_dashboard/components/workload_stats.vue';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import { useFakeDate } from 'helpers/fake_date';
import { mockKasTunnelUrl } from 'jest/environments/mock_data';
import {
  k8sPodsMock,
  mockPodStats,
  mockPodsTableItems,
} from 'jest/kubernetes_dashboard/graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/environment_details/components/kubernetes/kubernetes_pods.vue', () => {
  let wrapper;

  const namespace = 'my-kubernetes-namespace';
  const configuration = {
    basePath: mockKasTunnelUrl,
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTab = () => wrapper.findComponent(GlTab);
  const findWorkloadStats = () => wrapper.findComponent(WorkloadStats);
  const findWorkloadTable = () => wrapper.findComponent(WorkloadTable);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findFilteredMessage = () => wrapper.findByTestId('pods-filtered-message');

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sPods: jest.fn().mockReturnValue(k8sPodsMock),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (apolloProvider = createApolloProvider()) => {
    wrapper = shallowMountExtended(KubernetesPods, {
      propsData: { namespace, configuration },
      apolloProvider,
      stubs: {
        GlTab,
        GlSprintf,
      },
    });
  };

  describe('mounted', () => {
    it('renders pods tab', () => {
      createWrapper();

      expect(findTab().text()).toMatchInterpolatedText('Pods 0');
    });

    it('shows the loading icon', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('emits loading state', async () => {
      createWrapper();
      expect(wrapper.emitted('loading')[0]).toEqual([true]);

      await waitForPromises();
      expect(wrapper.emitted('loading')[1]).toEqual([false]);
    });

    it('hides the loading icon when the list of pods loaded', async () => {
      createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when gets pods data', () => {
    useFakeDate(2023, 10, 23, 10, 10);

    it('renders workload stats with the correct data', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadStats().props('stats')).toEqual(mockPodStats);
    });

    it('renders workload table with the correct data', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadTable().props('items')).toMatchObject(mockPodsTableItems);
    });

    it('provides correct actions data to the workload table', async () => {
      createWrapper();
      await waitForPromises();

      const actions = [
        {
          name: 'delete-pod',
          text: 'Delete pod',
          icon: 'remove',
          variant: 'danger',
          class: '!gl-text-red-500',
        },
      ];
      const items = findWorkloadTable().props('items');

      items.forEach((item) => {
        expect(item.actions).toEqual(actions);
      });
    });

    it('emits a update-failed-state event for each pod', async () => {
      createWrapper();
      await waitForPromises();

      expect(wrapper.emitted('update-failed-state')).toHaveLength(4);
      expect(wrapper.emitted('update-failed-state')).toEqual([
        [{ pods: false }],
        [{ pods: false }],
        [{ pods: false }],
        [{ pods: true }],
      ]);
    });

    it('emits select-item event on item select', async () => {
      createWrapper();
      await waitForPromises();

      expect(wrapper.emitted('select-item')).toBeUndefined();

      findWorkloadTable().vm.$emit('select-item', mockPodsTableItems[0]);
      expect(wrapper.emitted('select-item')).toEqual([[mockPodsTableItems[0]]]);
    });

    it('emits delete-pod event when receives it from the WorkloadTable component', async () => {
      createWrapper();
      await waitForPromises();
      expect(wrapper.emitted('delete-pod')).toBeUndefined();

      findWorkloadTable().vm.$emit('delete-pod', mockPodsTableItems[0]);
      expect(wrapper.emitted('delete-pod')).toHaveLength(1);
    });

    it('filters pods when receives a stat select event', async () => {
      createWrapper();
      await waitForPromises();

      const status = 'Failed';
      findWorkloadStats().vm.$emit('select', status);
      await nextTick();

      const filteredPods = mockPodsTableItems.filter((pod) => pod.status === status);
      expect(findWorkloadTable().props('items')).toMatchObject(filteredPods);
    });

    describe('searching pods', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
      });

      it('filters pods when receives a search', async () => {
        const searchTerm = 'pod-2';

        findSearchBox().vm.$emit('input', searchTerm);
        await nextTick();

        const filteredPods = [
          {
            name: 'pod-2',
            namespace: 'new-namespace',
            status: 'Pending',
            age: '1d',
            labels: { key: 'value' },
            annotations: { annotation: 'text', another: 'text' },
            kind: 'Pod',
            spec: {},
          },
        ];
        expect(findWorkloadTable().props('items')).toMatchObject(filteredPods);
      });

      describe('when a status is selected', () => {
        const searchTerm = 'pod';
        const status = 'Pending';

        beforeEach(async () => {
          findWorkloadStats().vm.$emit('select', status);
          await nextTick();
        });

        it('filter search results for the selected status', async () => {
          findSearchBox().vm.$emit('input', searchTerm);
          await nextTick();

          const filteredPods = [
            {
              name: 'pod-2',
              namespace: 'new-namespace',
              status: 'Pending',
              age: '1d',
              labels: { key: 'value' },
              annotations: { annotation: 'text', another: 'text' },
              kind: 'Pod',
              spec: {},
            },
          ];
          expect(findWorkloadTable().props('items')).toMatchObject(filteredPods);
        });

        it('shows a message', async () => {
          expect(findFilteredMessage().exists()).toBe(false);

          findSearchBox().vm.$emit('input', searchTerm);
          await nextTick();

          expect(findFilteredMessage().text()).toBe(
            `Showing search results with the status ${status}.`,
          );
        });
      });
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

    it("doesn't show pods table", () => {
      expect(findWorkloadTable().exists()).toBe(false);
    });

    it('emits an error message', () => {
      expect(wrapper.emitted('cluster-error')).toMatchObject([[error.message]]);
    });
  });
});
