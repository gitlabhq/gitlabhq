import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlTabs, GlTab, GlTable, GlPagination } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { useFakeDate } from 'helpers/fake_date';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesTabs from '~/environments/components/kubernetes_tabs.vue';
import { SERVICES_LIMIT_PER_PAGE } from '~/environments/constants';
import { mockKasTunnelUrl } from './mock_data';
import { k8sServicesMock } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/kubernetes_tabs.vue', () => {
  let wrapper;

  const configuration = {
    basePath: mockKasTunnelUrl,
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTab = (at) => wrapper.findAllComponents(GlTab).at(at);
  const findTable = () => wrapper.findComponent(GlTable);
  const findPagination = () => wrapper.findComponent(GlPagination);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sServices: jest.fn().mockReturnValue(k8sServicesMock),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (apolloProvider = createApolloProvider()) => {
    wrapper = shallowMount(KubernetesTabs, {
      propsData: { configuration },
      apolloProvider,
      stubs: {
        GlTab,
        GlTable: stubComponent(GlTable, {
          props: ['items', 'per-page'],
        }),
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

      expect(findTab(0).text()).toMatchInterpolatedText(`${KubernetesTabs.i18n.servicesTitle} 0`);
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
        expect(findTable().props('perPage')).toBe(SERVICES_LIMIT_PER_PAGE);
        expect(findTable().props('items')).toMatchObject([
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

      it("doesn't render pagination when services are less then SERVICES_LIMIT_PER_PAGE", async () => {
        createWrapper();
        await waitForPromises();

        expect(findPagination().exists()).toBe(false);
      });
    });

    it('shows pagination when services are more then SERVICES_LIMIT_PER_PAGE', async () => {
      const createApolloProviderWithPagination = () => {
        const mockResolvers = {
          Query: {
            k8sServices: jest
              .fn()
              .mockReturnValue(
                Array.from({ length: 6 }, () => k8sServicesMock).flatMap((array) => array),
              ),
          },
        };

        return createMockApollo([], mockResolvers);
      };

      createWrapper(createApolloProviderWithPagination());
      await waitForPromises();

      expect(findPagination().exists()).toBe(true);
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

      expect(wrapper.emitted('cluster-error')).toEqual([[error]]);
    });
  });
});
