import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesPods from '~/environments/components/kubernetes_pods.vue';
import { mockKasTunnelUrl } from './mock_data';
import { k8sPodsMock } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/kubernetes_pods.vue', () => {
  let wrapper;

  const namespace = 'my-kubernetes-namespace';
  const configuration = {
    basePath: mockKasTunnelUrl,
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAllStats = () => wrapper.findAllComponents(GlSingleStat);
  const findSingleStat = (at) => findAllStats().at(at);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sPods: jest.fn().mockReturnValue(k8sPodsMock),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (apolloProvider = createApolloProvider()) => {
    wrapper = shallowMount(KubernetesPods, {
      propsData: { namespace, configuration },
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

      expect(findAllStats()).toHaveLength(4);
    });

    it.each`
      count | title                                | index
      ${2}  | ${KubernetesPods.i18n.runningPods}   | ${0}
      ${1}  | ${KubernetesPods.i18n.pendingPods}   | ${1}
      ${1}  | ${KubernetesPods.i18n.succeededPods} | ${2}
      ${2}  | ${KubernetesPods.i18n.failedPods}    | ${3}
    `(
      'renders stat with title "$title" and count "$count" at index $index',
      async ({ count, title, index }) => {
        createWrapper();
        await waitForPromises();

        expect(findSingleStat(index).props()).toMatchObject({
          value: count,
          title,
        });
      },
    );
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
      expect(findAllStats()).toHaveLength(0);
    });

    it('emits an error message', () => {
      expect(wrapper.emitted('cluster-error')).toMatchObject([[error]]);
    });
  });
});
