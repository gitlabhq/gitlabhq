<script>
import { GlTooltipDirective, GlBadge } from '@gitlab/ui';
import k8sConnectionStatusQuery from '~/environments/graphql/queries/k8s_connection_status.query.graphql';
import reconnectToClusterMutation from '~/environments/graphql/mutations/reconnect_to_cluster.mutation.graphql';
import { s__ } from '~/locale';
import { connectionStatus } from '~/environments/graphql/resolvers/kubernetes/constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    configuration: {
      type: Object,
      required: true,
    },
    namespace: {
      type: String,
      required: true,
    },
    resourceType: {
      type: String,
      required: true,
    },
  },
  apollo: {
    k8sConnection: {
      query: k8sConnectionStatusQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      error(error) {
        this.$emit('error', error);
      },
    },
  },
  data() {
    return {
      k8sConnection: {
        [this.resourceType]: {
          connectionStatus: connectionStatus.disconnected,
        },
      },
    };
  },
  computed: {
    k8sResourceConnectionStatus() {
      const k8sResource = this.k8sConnection?.[this.resourceType];
      return k8sResource?.connectionStatus;
    },
    isLoading() {
      return this.k8sResourceConnectionStatus === connectionStatus.connecting;
    },
    isDisabled() {
      return this.k8sResourceConnectionStatus !== connectionStatus.disconnected;
    },
    statusIcon() {
      switch (this.k8sResourceConnectionStatus) {
        case connectionStatus.connecting:
          return 'spinner';
        case connectionStatus.connected:
          return 'connected';
        case connectionStatus.disconnected:
          return 'retry';
        default:
          return '';
      }
    },
    tooltipText() {
      switch (this.k8sResourceConnectionStatus) {
        case connectionStatus.connecting:
          return s__('Environments|Updating dashboard');
        case connectionStatus.connected:
          return s__('Environments|Dashboard is up to date');
        case connectionStatus.disconnected:
          return s__('Environments|Refresh to sync new data');
        default:
          return '';
      }
    },
    badgeText() {
      switch (this.k8sResourceConnectionStatus) {
        case connectionStatus.connecting:
          return s__('Environments|Updating');
        case connectionStatus.connected:
          return s__('Environments|Dashboard synced');
        case connectionStatus.disconnected:
          return s__('Environments|Refresh dashboard');
        default:
          return '';
      }
    },
    badgeVariant() {
      switch (this.k8sResourceConnectionStatus) {
        case connectionStatus.connected:
          return 'success';
        case connectionStatus.disconnected:
          return 'warning';
        default:
          return 'muted';
      }
    },
    badgeHref() {
      if (this.isDisabled || this.isLoading) {
        return null;
      }
      return '#';
    },
  },
  methods: {
    reconnect() {
      if (this.isDisabled || this.isLoading) {
        return;
      }

      this.$apollo
        .mutate({
          mutation: reconnectToClusterMutation,
          variables: {
            configuration: this.configuration,
            namespace: this.namespace,
            resourceType: this.resourceType,
          },
        })
        .catch((error) => {
          this.$emit('error', error);
        });
    },
  },
};
</script>
<template>
  <div
    v-gl-tooltip
    :title="tooltipText"
    class="gl-display-flex gl-align-items-center gl-flex-shrink-0 gl-mb-2"
    data-testid="connection-status-tooltip"
  >
    <gl-badge
      :variant="badgeVariant"
      :icon="statusIcon"
      :href="badgeHref"
      @click.native="reconnect"
    >
      {{ badgeText }}
    </gl-badge>
  </div>
</template>
