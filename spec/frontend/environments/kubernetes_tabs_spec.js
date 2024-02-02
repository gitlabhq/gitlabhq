import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesTabs from '~/environments/components/kubernetes_tabs.vue';
import { SERVICES_LIMIT_PER_PAGE } from '~/environments/constants';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import { SERVICES_TABLE_FIELDS } from '~/kubernetes_dashboard/constants';

import { mockKasTunnelUrl } from './mock_data';
import { k8sServicesMock } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/kubernetes_tabs.vue', () => {
  let wrapper;

  const namespace = 'my-kubernetes-namespace';
  const configuration = {
    basePath: mockKasTunnelUrl,
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTabs = () => wrapper.findComponent(GlTabs);
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
    wrapper = shallowMountExtended(KubernetesTabs, {
      propsData: { configuration, namespace },
      apolloProvider,
      stubs: {
        GlTab,
        GlBadge,
      },
    });
  };

  describe('mounted', () => {
    it('shows tabs', () => {
      createWrapper();

      expect(findTabs().exists()).toBe(true);
    });

    it('renders services tab', () => {
      createWrapper();

      expect(findTab().text()).toMatchInterpolatedText(`${KubernetesTabs.i18n.servicesTitle} 0`);
    });
  });

  describe('services tab', () => {
    useFakeDate(2020, 6, 6);
    it('shows the loading icon', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    describe('when services data is loaded', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
      });

      it('hides the loading icon when the list of services loaded', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('renders services table when gets services data', () => {
        expect(findWorkloadTable().props('pageSize')).toBe(SERVICES_LIMIT_PER_PAGE);
        expect(findWorkloadTable().props('fields')).toBe(SERVICES_TABLE_FIELDS);
        expect(findWorkloadTable().props('items')).toMatchObject([
          {
            name: 'my-first-service',
            namespace: 'default',
            type: 'ClusterIP',
            clusterIP: '10.96.0.1',
            externalIP: '-',
            ports: '443/TCP',
            age: '0s',
          },
          {
            name: 'my-second-service',
            namespace: 'default',
            type: 'NodePort',
            clusterIP: '10.105.219.238',
            externalIP: '-',
            ports: '80:31989/TCP, 443:32679/TCP',
            age: '2d',
          },
        ]);
      });
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
