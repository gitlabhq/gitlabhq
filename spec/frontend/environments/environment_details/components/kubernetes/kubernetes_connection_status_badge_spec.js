import { GlBadge, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import KubernetesConnectionStatusBadge from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status_badge.vue';
import { connectionStatus } from '~/environments/graphql/resolvers/kubernetes/constants';

describe('~/environments/environment_details/components/kubernetes/kubernetes_connection_status.vue', () => {
  let wrapper;

  const defaultProps = {
    popoverId: 'popover-id',
    connectionStatus: connectionStatus.connected,
  };

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };
    wrapper = shallowMount(KubernetesConnectionStatusBadge, {
      propsData,
    });
  }

  const findReconnectBadge = () => wrapper.findComponent(GlBadge);
  const findReconnectTooltip = () => wrapper.findComponent(GlPopover);

  describe.each([
    [connectionStatus.connected, 'success', 'connected', undefined, 'Synced', false],
    [connectionStatus.disconnected, 'warning', 'retry', '#', 'Refresh', true],
    [connectionStatus.connecting, 'muted', 'spinner', undefined, 'Updating', false],
    // eslint-disable-next-line max-params
  ])('when connection status is %s', (status, variant, icon, href, text, shouldReconnect) => {
    beforeEach(() => {
      createComponent({ connectionStatus: status });
    });

    it('renders the correct badge', () => {
      const badge = findReconnectBadge();
      expect(badge.props().variant).toBe(variant);
      expect(badge.props().icon).toBe(icon);
      expect(badge.attributes().href).toBe(href);
      expect(badge.text()).toBe(text);
    });

    it('renders the correct tooltip', () => {
      const tooltip = findReconnectTooltip();
      expect(tooltip.props().target).toBe('status-badge-popover-id');
    });

    describe('when badge is clicked', () => {
      beforeEach(() => {
        findReconnectBadge().vm.$emit('click');
      });

      if (shouldReconnect) {
        it('emits reconnect event', () => {
          expect(wrapper.emitted('reconnect')).toEqual([[]]);
        });
      } else {
        it('does not emit reconnect event', () => {
          expect(wrapper.emitted('reconnect')).toBeUndefined();
        });
      }
    });
  });
});
