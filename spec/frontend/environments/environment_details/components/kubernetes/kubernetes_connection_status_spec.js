import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlBadge } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import KubernetesConnectionStatus from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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
    resourceType: k8sResourceType.k8sPods,
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

  function createComponent(props = defaultProps) {
    const apolloProvider = createApolloProvider();
    wrapper = shallowMountExtended(KubernetesConnectionStatus, {
      propsData: {
        ...props,
      },
      apolloProvider,
    });
  }

  const findReconnectBadge = () => wrapper.findComponent(GlBadge);
  const findReconnectTooltip = () => wrapper.findByTestId('connection-status-tooltip');

  beforeEach(() => {
    setUpMocks();
  });

  describe('when not connected to cluster', () => {
    beforeEach(async () => {
      k8sConnectionQueryMock.mockResolvedValue({
        ...defaultK8sConnectionState,
        [k8sResourceType.k8sPods]: { connectionStatus: connectionStatus.disconnected },
      });
      createComponent();
      await waitForPromises();
    });

    it('renders the disconnected icon', () => {
      const badge = findReconnectBadge();
      expect(badge.props().variant).toBe('warning');
      expect(badge.props().icon).toBe('retry');
      expect(badge.attributes().href).toBe('#');
    });

    it('renders the correct tooltip', () => {
      const tooltip = findReconnectTooltip();
      expect(tooltip.attributes('title')).toBe('Refresh to sync new data');
    });

    it('when the button is clicked, it calls the reconnectToCluster mutation', async () => {
      const badge = findReconnectBadge();
      badge.trigger('click');
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

  describe('when connected to cluster', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the connected icon', () => {
      const badge = findReconnectBadge();
      expect(badge.props().variant).toBe('success');
      expect(badge.props().icon).toBe('connected');
      expect(badge.attributes().href).toBeUndefined();
    });

    it('renders the correct tooltip', () => {
      const tooltip = findReconnectTooltip();
      expect(tooltip.attributes('title')).toBe('Dashboard is up to date');
    });

    it('when the button is clicked, it does not call the reconnectToCluster mutation', async () => {
      const badge = findReconnectBadge();
      badge.trigger('click');
      await waitForPromises();
      expect(reconnectToClusterMutationMock).not.toHaveBeenCalled();
    });
  });

  describe('when connecting to cluster', () => {
    beforeEach(async () => {
      k8sConnectionQueryMock.mockResolvedValue({
        ...defaultK8sConnectionState,
        [k8sResourceType.k8sPods]: { connectionStatus: connectionStatus.connecting },
      });
      createComponent();
      await waitForPromises();
    });

    it('renders the correct tooltip', () => {
      const tooltip = findReconnectTooltip();
      expect(tooltip.attributes('title')).toBe('Updating dashboard');
    });

    it('renders the loading icon', () => {
      const badge = findReconnectBadge();
      expect(badge.props().variant).toBe('muted');
      expect(badge.props().icon).toBe('spinner');
      expect(badge.attributes().href).toBeUndefined();
    });
  });
});
