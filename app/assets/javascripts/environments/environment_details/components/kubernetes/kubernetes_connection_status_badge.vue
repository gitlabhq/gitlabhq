<script>
import { GlBadge, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import { connectionStatus } from '~/environments/graphql/resolvers/kubernetes/constants';

export default {
  components: {
    GlBadge,
    GlPopover,
  },
  props: {
    popoverId: {
      type: String,
      required: true,
    },
    connectionStatus: {
      type: String,
      required: true,
    },
  },
  computed: {
    statusBadgeId() {
      return `status-badge-${this.popoverId}`;
    },
    statusIcon() {
      switch (this.connectionStatus) {
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
      switch (this.connectionStatus) {
        case connectionStatus.connecting:
          return s__('Environments|Retrieving resource status');
        case connectionStatus.connected:
          return s__('Environments|Resource is up to date');
        case connectionStatus.disconnected:
          return s__('Environments|Refresh to sync new data');
        default:
          return '';
      }
    },
    badgeText() {
      switch (this.connectionStatus) {
        case connectionStatus.connecting:
          return s__('Environments|Updating');
        case connectionStatus.connected:
          return s__('Environments|Synced');
        case connectionStatus.disconnected:
          return s__('Environments|Refresh');
        default:
          return '';
      }
    },
    badgeVariant() {
      switch (this.connectionStatus) {
        case connectionStatus.connected:
          return 'success';
        case connectionStatus.disconnected:
          return 'warning';
        default:
          return 'muted';
      }
    },
    badgeHref() {
      return this.connectionStatus === connectionStatus.disconnected ? '#' : undefined;
    },
  },
  methods: {
    onClick() {
      if (this.connectionStatus !== connectionStatus.disconnected) {
        return;
      }
      this.$emit('reconnect');
    },
  },
};
</script>
<template>
  <div :id="statusBadgeId">
    <gl-badge
      :variant="badgeVariant"
      :icon="statusIcon"
      :href="badgeHref"
      tabindex="0"
      @click.native="onClick"
    >
      {{ badgeText }}
    </gl-badge>
    <gl-popover :target="statusBadgeId">
      {{ tooltipText }}
    </gl-popover>
  </div>
</template>
