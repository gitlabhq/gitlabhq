import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlTab } from '@gitlab/ui';
import { useFakeDate } from 'helpers/fake_date';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesServices from '~/environments/environment_details/components/kubernetes/kubernetes_services.vue';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import { SERVICES_LIMIT_PER_PAGE } from '~/environments/constants';
import { SERVICES_TABLE_FIELDS } from '~/kubernetes_dashboard/constants';
import { mockKasTunnelUrl } from 'jest/environments/mock_data';
import {
  k8sServicesMock,
  mockServicesTableItems,
} from 'jest/kubernetes_dashboard/graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/environment_details/components/kubernetes/kubernetes_services.vue', () => {
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
  const findWorkloadTable = () => wrapper.findComponent(WorkloadTable);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sServices: jest.fn().mockReturnValue(k8sServicesMock),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (apolloProvider = createApolloProvider()) => {
    wrapper = shallowMount(KubernetesServices, {
      propsData: { configuration, namespace },
      apolloProvider,
      stubs: {
        GlTab,
      },
    });
  };

  describe('mounted', () => {
    it('renders services tab', () => {
      createWrapper();

      expect(findTab().text()).toMatchInterpolatedText('Services 0');
    });

    it('shows the loading icon', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when gets services data', () => {
    useFakeDate(2023, 10, 23, 10, 10);

    it('hides the loading icon when the list of services loaded', async () => {
      createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders services table when gets services data', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadTable().props('pageSize')).toBe(SERVICES_LIMIT_PER_PAGE);
      expect(findWorkloadTable().props('fields')).toBe(SERVICES_TABLE_FIELDS);
      expect(findWorkloadTable().props('items')).toMatchObject(mockServicesTableItems);
    });

    it('emits select-item event on item select', async () => {
      createWrapper();
      await waitForPromises();

      expect(wrapper.emitted('select-item')).toBeUndefined();

      findWorkloadTable().vm.$emit('select-item', mockServicesTableItems[0]);
      expect(wrapper.emitted('select-item')).toEqual([[mockServicesTableItems[0]]]);
    });

    it('emits an error message when gets an error from the cluster_client API', async () => {
      const error = new Error('Error from the cluster_client API');
      const createErroredApolloProvider = () => {
        const mockResolvers = {
          Query: {
            k8sServices: jest.fn().mockRejectedValueOnce(error),
          },
        };

        return createMockApollo([], mockResolvers);
      };

      createWrapper(createErroredApolloProvider());
      await waitForPromises();

      expect(wrapper.emitted('cluster-error')).toEqual([[error.message]]);
    });
  });
});
