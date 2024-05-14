import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesConnectionStatusBadge from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status_badge.vue';
import KubernetesConnectionStatus from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status.vue';
import waitForPromises from 'helpers/wait_for_promises';
import {
  connectionStatus,
  k8sResourceType,
} from '~/environments/graphql/resolvers/kubernetes/constants';
import { kubernetesNamespace } from '../../../graphql/mock_data';
import { mockKasTunnelUrl } from '../../../mock_data';

Vue.use(VueApollo);

describe('~/environments/environment_details/components/kubernetes/kubernetes_connection_status.vue', () => {
  let wrapper;

  const configuration = {
    basePath: mockKasTunnelUrl.replace(/\/$/, ''),
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
      withCredentials: true,
    },
  };

  const defaultProps = {
    configuration,
    namespace: kubernetesNamespace,
    resourceTypeParam: {
      resourceType: k8sResourceType.k8sPods,
      connectionParams: null,
    },
  };

  const defaultK8sConnectionState = {
    [k8sResourceType.k8sPods]: {
      connectionStatus: connectionStatus.connected,
    },
    [k8sResourceType.k8sServices]: {
      connectionStatus: connectionStatus.connected,
    },
  };
  let k8sConnectionQueryMock;

  let reconnectToClusterMutationMock;

  const setUpMocks = () => {
    k8sConnectionQueryMock = jest.fn().mockResolvedValue(defaultK8sConnectionState);
    reconnectToClusterMutationMock = jest.fn();
  };

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sConnection: k8sConnectionQueryMock,
      },
      Mutation: {
        reconnectToCluster: reconnectToClusterMutationMock,
      },
    };

    return createMockApollo([], mockResolvers);
  };

  function createComponent(props = defaultProps, scopedSlots) {
    const apolloProvider = createApolloProvider();
    wrapper = shallowMount(KubernetesConnectionStatus, {
      propsData: {
        ...props,
      },
      scopedSlots,
      apolloProvider,
    });
  }

  const findStatusBadge = () => wrapper.findComponent(KubernetesConnectionStatusBadge);

  beforeEach(() => {
    setUpMocks();
  });

  describe('when a default slot is rendered', () => {
    describe.each([
      [connectionStatus.connected],
      [connectionStatus.connecting],
      [connectionStatus.disconnected],
    ])('when %s to cluster', (status) => {
      beforeEach(async () => {
        k8sConnectionQueryMock.mockResolvedValue({
          ...defaultK8sConnectionState,
          [k8sResourceType.k8sPods]: { connectionStatus: status },
        });
        createComponent();
        await waitForPromises();
      });

      it('renders status badge with correct props', () => {
        const badge = findStatusBadge();
        expect(badge.props().popoverId).toBe(k8sResourceType.k8sPods);
        expect(badge.props().connectionStatus).toBe(status);
      });

      it('when reconnect event is emitted, it calls the reconnectToCluster mutation', async () => {
        const badge = findStatusBadge();
        badge.vm.$emit('reconnect');
        await waitForPromises();
        expect(reconnectToClusterMutationMock).toHaveBeenCalledWith(
          {},
          {
            ...defaultProps,
          },
          expect.anything(),
          expect.anything(),
        );
      });
    });
  });

  describe('when a custom slot is rendered', () => {
    const scopedSlotSpy = jest.fn();

    describe.each([
      [connectionStatus.connected],
      [connectionStatus.connecting],
      [connectionStatus.disconnected],
    ])('when %s to cluster', (status) => {
      beforeEach(async () => {
        k8sConnectionQueryMock.mockResolvedValue({
          ...defaultK8sConnectionState,
          [k8sResourceType.k8sPods]: { connectionStatus: status },
        });
        createComponent(defaultProps, { default: scopedSlotSpy });
        await waitForPromises();
      });

      it('correctly passes scoped slot props', () => {
        expect(scopedSlotSpy).toHaveBeenCalledWith({
          connectionProps: {
            connectionStatus: status,
            reconnect: expect.any(Function),
          },
        });
      });
    });
  });
});
