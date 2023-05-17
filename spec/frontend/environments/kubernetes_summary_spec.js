import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTab, GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesSummary from '~/environments/components/kubernetes_summary.vue';
import { mockKasTunnelUrl } from './mock_data';
import { k8sWorkloadsMock } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/kubernetes_summary.vue', () => {
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
  const findSummaryListItem = (at) => wrapper.findAllByTestId('summary-list-item').at(at);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sWorkloads: jest.fn().mockReturnValue(k8sWorkloadsMock),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (apolloProvider = createApolloProvider()) => {
    wrapper = shallowMountExtended(KubernetesSummary, {
      propsData: { configuration, namespace },
      apolloProvider,
      stubs: {
        GlTab,
        GlBadge,
      },
    });
  };

  describe('mounted', () => {
    it('renders summary tab', () => {
      createWrapper();

      expect(findTab().text()).toMatchInterpolatedText(`${KubernetesSummary.i18n.summaryTitle} 0`);
    });

    it('shows the loading icon', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    describe('when workloads data is loaded', () => {
      beforeEach(async () => {
        await createWrapper();
        await waitForPromises();
      });

      it('hides the loading icon when the list of workload types loaded', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it.each`
        type              | successText    | successCount | failedCount | suspendedCount | index
        ${'Deployments'}  | ${'ready'}     | ${1}         | ${1}        | ${0}           | ${0}
        ${'DaemonSets'}   | ${'ready'}     | ${1}         | ${2}        | ${0}           | ${1}
        ${'StatefulSets'} | ${'ready'}     | ${2}         | ${1}        | ${0}           | ${2}
        ${'ReplicaSets'}  | ${'ready'}     | ${1}         | ${1}        | ${0}           | ${3}
        ${'Jobs'}         | ${'completed'} | ${2}         | ${1}        | ${0}           | ${4}
        ${'CronJobs'}     | ${'ready'}     | ${1}         | ${1}        | ${1}           | ${5}
      `(
        'populates view with the correct badges for workload type $type',
        ({ type, successText, successCount, failedCount, suspendedCount, index }) => {
          const findAllBadges = () => findSummaryListItem(index).findAllComponents(GlBadge);
          const findBadgeByVariant = (variant) =>
            findAllBadges().wrappers.find((badge) => badge.props('variant') === variant);

          expect(findSummaryListItem(index).text()).toContain(type);
          expect(findBadgeByVariant('success').text()).toBe(`${successCount} ${successText}`);
          expect(findBadgeByVariant('danger').text()).toBe(`${failedCount} failed`);
          if (suspendedCount > 0) {
            expect(findBadgeByVariant('neutral').text()).toBe(`${suspendedCount} suspended`);
          }
        },
      );
    });

    it('emits an error message when gets an error from the cluster_client API', async () => {
      const error = new Error('Error from the cluster_client API');
      const createErroredApolloProvider = () => {
        const mockResolvers = {
          Query: {
            k8sWorkloads: jest.fn().mockRejectedValueOnce(error),
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
