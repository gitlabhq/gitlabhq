<script>
import { GlLoadingIcon, GlBadge, GlPopover, GlSprintf, GlLink } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import {
  CLUSTER_HEALTH_SUCCESS,
  CLUSTER_HEALTH_ERROR,
  HEALTH_BADGES,
  SYNC_STATUS_BADGES,
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';
import { fluxSyncStatus } from '~/environments/helpers/k8s_integration_helper';
import KubernetesConnectionStatus from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status.vue';
import KubernetesConnectionStatusBadge from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status_badge.vue';
import {
  k8sResourceType,
  connectionStatus,
} from '~/environments/graphql/resolvers/kubernetes/constants';

export default {
  components: {
    KubernetesConnectionStatus,
    KubernetesConnectionStatusBadge,
    GlLoadingIcon,
    GlBadge,
    GlPopover,
    GlSprintf,
    GlLink,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    clusterHealthStatus: {
      required: false,
      type: String,
      default: '',
      validator(val) {
        return [CLUSTER_HEALTH_ERROR, CLUSTER_HEALTH_SUCCESS, ''].includes(val);
      },
    },
    configuration: {
      required: true,
      type: Object,
    },
    environmentName: {
      required: true,
      type: String,
    },
    namespace: {
      required: true,
      type: String,
    },
    fluxResourcePath: {
      required: false,
      type: String,
      default: '',
    },
    resourceType: {
      type: String,
      required: true,
    },
    fluxResourceStatus: {
      type: Array,
      required: false,
      default: () => [],
    },
    fluxApiError: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      clusterResourceTypeParams: {
        [k8sResourceType.k8sServices]: {
          resourceType: k8sResourceType.k8sServices,
          connectionParams: null,
        },
        [k8sResourceType.k8sPods]: {
          resourceType: k8sResourceType.k8sPods,
          connectionParams: null,
        },
        [k8sResourceType.fluxKustomizations]: {
          resourceType: k8sResourceType.fluxKustomizations,
          connectionParams: {
            fluxResourcePath: this.fluxResourcePath,
          },
        },
        [k8sResourceType.fluxHelmReleases]: {
          resourceType: k8sResourceType.fluxHelmReleases,
          connectionParams: {
            fluxResourcePath: this.fluxResourcePath,
          },
        },
      },
    };
  },
  computed: {
    fluxConnectionParams() {
      if (this.isUsingKustomizationConfiguration) {
        return {
          resourceType: k8sResourceType.fluxKustomizations,
          connectionParams: {
            fluxResourcePath: this.fluxResourcePath,
          },
        };
      }
      if (this.isUsingHelmConfiguration) {
        return {
          resourceType: k8sResourceType.fluxHelmReleases,
          connectionParams: {
            fluxResourcePath: this.fluxResourcePath,
          },
        };
      }
      return {};
    },
    isUsingKustomizationConfiguration() {
      return Boolean(this.fluxResourcePath?.includes(KUSTOMIZATIONS_RESOURCE_TYPE));
    },
    isUsingHelmConfiguration() {
      return Boolean(this.fluxResourcePath?.includes(HELM_RELEASES_RESOURCE_TYPE));
    },
    healthBadge() {
      return HEALTH_BADGES[this.clusterHealthStatus];
    },
    fluxBadgeId() {
      return `${this.environmentName}-flux-sync-badge`;
    },
    syncStatusBadge() {
      if (!this.fluxResourcePresent && this.fluxApiError) {
        return { ...SYNC_STATUS_BADGES.unavailable, popoverText: this.fluxApiError };
      }
      if (!this.fluxResourcePresent) {
        return SYNC_STATUS_BADGES.unavailable;
      }

      const fluxStatus = fluxSyncStatus(this.fluxResourceStatus);

      switch (fluxStatus.status) {
        case 'failed':
          return {
            ...SYNC_STATUS_BADGES.failed,
            popoverText: fluxStatus.message,
          };
        case 'stalled':
          return {
            ...SYNC_STATUS_BADGES.stalled,
            popoverText: fluxStatus.message,
          };
        case 'reconcilingWithBadConfig':
          return {
            ...SYNC_STATUS_BADGES.reconciling,
            popoverText: fluxStatus.message,
          };
        case 'reconciling':
          return SYNC_STATUS_BADGES.reconciling;
        case 'reconciled':
          return SYNC_STATUS_BADGES.reconciled;
        default:
          return SYNC_STATUS_BADGES.unknown;
      }
    },
    isFluxConnectionStatus() {
      return Boolean(this.fluxConnectionParams.resourceType);
    },
    fluxResourcePresent() {
      return Boolean(this.fluxResourceStatus?.length);
    },
    fluxBadgeHref() {
      return this.fluxResourcePresent ? '#' : null;
    },
  },
  methods: {
    handleError(error) {
      this.$emit('error', error);
    },
    toggleFluxResource() {
      if (!this.fluxResourcePresent) return;

      this.$emit('show-flux-resource-details');
    },
  },
  i18n: {
    healthLabel: s__('Environment|Environment status'),
    syncStatusLabel: s__('Environment|Flux Sync'),
    dashboardStatusLabel: s__('Environment|Dashboard'),
  },
  k8sResourceType,
  connectionStatus,
  badgeContainerClasses: 'gl-flex gl-items-center gl-shrink-0 gl-mr-3 gl-mb-2',
};
</script>
<template>
  <div class="gl-flex gl-flex-wrap">
    <div :class="$options.badgeContainerClasses">
      <span class="gl-mr-3">{{ $options.i18n.healthLabel }}</span>
      <gl-loading-icon v-if="!clusterHealthStatus" size="sm" inline />
      <gl-badge
        v-else-if="healthBadge"
        :icon="healthBadge.icon"
        :variant="healthBadge.variant"
        data-testid="health-badge"
        >{{ healthBadge.text }}
      </gl-badge>
    </div>
    <kubernetes-connection-status
      #default="{ connectionProps }"
      data-testid="flux-connection-status"
      :class="$options.badgeContainerClasses"
      :configuration="configuration"
      :namespace="namespace"
      :resource-type-param="fluxConnectionParams"
    >
      <span class="gl-mr-3">{{ $options.i18n.syncStatusLabel }}</span>
      <kubernetes-connection-status-badge
        v-if="
          isFluxConnectionStatus &&
          connectionProps.connectionStatus !== $options.connectionStatus.connected
        "
        data-testid="flux-status-badge"
        :popover-id="$options.k8sResourceType.fluxKustomizations"
        :connection-status="connectionProps.connectionStatus"
        @reconnect="connectionProps.reconnect"
      />
      <template v-else>
        <gl-badge
          :id="fluxBadgeId"
          :icon="syncStatusBadge.icon"
          :variant="syncStatusBadge.variant"
          data-testid="sync-badge"
          tabindex="0"
          :href="fluxBadgeHref"
          @click.native="toggleFluxResource"
          >{{ syncStatusBadge.text }}
        </gl-badge>
        <gl-popover :target="fluxBadgeId" :title="syncStatusBadge.popoverTitle">
          <gl-sprintf :message="syncStatusBadge.popoverText">
            <template #link="{ content }">
              <gl-link :href="syncStatusBadge.popoverLink" class="gl-font-sm">{{
                content
              }}</gl-link></template
            >
          </gl-sprintf>
        </gl-popover>
      </template>
    </kubernetes-connection-status>
    <kubernetes-connection-status
      #default="{ connectionProps }"
      data-testid="dashboard-status-badge"
      :configuration="configuration"
      :namespace="namespace"
      :resource-type-param="clusterResourceTypeParams[resourceType]"
      :class="$options.badgeContainerClasses"
      @error="handleError"
    >
      <span class="gl-mr-3">{{ $options.i18n.dashboardStatusLabel }}</span>
      <kubernetes-connection-status-badge
        :popover-id="resourceType"
        :connection-status="connectionProps.connectionStatus"
        @reconnect="connectionProps.reconnect"
      />
    </kubernetes-connection-status>
  </div>
</template>
