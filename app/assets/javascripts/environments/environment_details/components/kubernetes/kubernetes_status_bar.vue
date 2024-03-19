<script>
import { GlLoadingIcon, GlBadge, GlPopover, GlSprintf, GlLink } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import {
  CLUSTER_HEALTH_SUCCESS,
  CLUSTER_HEALTH_ERROR,
  HEALTH_BADGES,
  SYNC_STATUS_BADGES,
  STATUS_TRUE,
  STATUS_FALSE,
  STATUS_UNKNOWN,
  REASON_PROGRESSING,
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';
import fluxKustomizationStatusQuery from '~/environments/graphql/queries/flux_kustomization_status.query.graphql';
import fluxHelmReleaseStatusQuery from '~/environments/graphql/queries/flux_helm_release_status.query.graphql';
import KubernetesConnectionStatus from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status.vue';

export default {
  components: {
    KubernetesConnectionStatus,
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
  },
  apollo: {
    fluxKustomizationStatus: {
      query: fluxKustomizationStatusQuery,
      variables() {
        return {
          configuration: this.configuration,
          fluxResourcePath: this.fluxResourcePath,
        };
      },
      skip() {
        return Boolean(
          !this.fluxResourcePath || this.fluxResourcePath?.includes(HELM_RELEASES_RESOURCE_TYPE),
        );
      },
      error(err) {
        this.fluxApiError = err.message;
      },
    },
    fluxHelmReleaseStatus: {
      query: fluxHelmReleaseStatusQuery,
      variables() {
        return {
          configuration: this.configuration,
          fluxResourcePath: this.fluxResourcePath,
        };
      },
      skip() {
        return Boolean(
          !this.fluxResourcePath || this.fluxResourcePath?.includes(KUSTOMIZATIONS_RESOURCE_TYPE),
        );
      },
      error(err) {
        this.fluxApiError = err.message;
      },
    },
  },
  data() {
    return {
      fluxApiError: '',
    };
  },
  computed: {
    healthBadge() {
      return HEALTH_BADGES[this.clusterHealthStatus];
    },
    hasKustomizations() {
      return this.fluxKustomizationStatus?.length;
    },
    hasHelmReleases() {
      return this.fluxHelmReleaseStatus?.length;
    },
    isLoading() {
      return (
        this.$apollo.queries.fluxKustomizationStatus.loading ||
        this.$apollo.queries.fluxHelmReleaseStatus.loading
      );
    },
    fluxBadgeId() {
      return `${this.environmentName}-flux-sync-badge`;
    },
    fluxCRD() {
      if (!this.hasKustomizations && !this.hasHelmReleases) {
        return [];
      }

      return this.hasKustomizations ? this.fluxKustomizationStatus : this.fluxHelmReleaseStatus;
    },
    fluxAnyStalled() {
      return this.fluxCRD.find((condition) => {
        return condition.status === STATUS_TRUE && condition.type === 'Stalled';
      });
    },
    fluxAnyReconcilingWithBadConfig() {
      return this.fluxCRD.find((condition) => {
        return (
          condition.status === STATUS_UNKNOWN &&
          condition.type === 'Ready' &&
          condition.reason === REASON_PROGRESSING
        );
      });
    },
    fluxAnyReconciling() {
      return this.fluxCRD.find((condition) => {
        return condition.status === STATUS_TRUE && condition.type === 'Reconciling';
      });
    },
    fluxAnyReconciled() {
      return this.fluxCRD.find((condition) => {
        return condition.status === STATUS_TRUE && condition.type === 'Ready';
      });
    },
    fluxAnyFailed() {
      return this.fluxCRD.find((condition) => {
        return condition.status === STATUS_FALSE && condition.type === 'Ready';
      });
    },
    syncStatusBadge() {
      if (!this.fluxCRD.length && this.fluxApiError) {
        return { ...SYNC_STATUS_BADGES.unavailable, popoverText: this.fluxApiError };
      }
      if (!this.fluxCRD.length) {
        return SYNC_STATUS_BADGES.unavailable;
      }
      if (this.fluxAnyFailed) {
        return { ...SYNC_STATUS_BADGES.failed, popoverText: this.fluxAnyFailed.message };
      }
      if (this.fluxAnyStalled) {
        return { ...SYNC_STATUS_BADGES.stalled, popoverText: this.fluxAnyStalled.message };
      }
      if (this.fluxAnyReconcilingWithBadConfig) {
        return {
          ...SYNC_STATUS_BADGES.reconciling,
          popoverText: this.fluxAnyReconcilingWithBadConfig.message,
        };
      }
      if (this.fluxAnyReconciling) {
        return SYNC_STATUS_BADGES.reconciling;
      }
      if (this.fluxAnyReconciled) {
        return SYNC_STATUS_BADGES.reconciled;
      }
      return SYNC_STATUS_BADGES.unknown;
    },
    isReconnectButtonShown() {
      return this.glFeatures.k8sWatchApi;
    },
  },
  methods: {
    handleError(error) {
      this.$emit('error', error);
    },
  },
  i18n: {
    healthLabel: s__('Environment|Environment status'),
    syncStatusLabel: s__('Environment|Sync status'),
  },
  badgeContainerClasses: 'gl-display-flex gl-align-items-center gl-flex-shrink-0 gl-mr-3 gl-mb-2',
};
</script>
<template>
  <div class="gl-display-flex gl-flex-wrap">
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

    <div :class="$options.badgeContainerClasses">
      <span class="gl-mr-3">{{ $options.i18n.syncStatusLabel }}</span>
      <gl-loading-icon v-if="isLoading" size="sm" inline />
      <template v-else-if="syncStatusBadge">
        <gl-badge
          :id="fluxBadgeId"
          :icon="syncStatusBadge.icon"
          :variant="syncStatusBadge.variant"
          data-testid="sync-badge"
          tabindex="0"
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
    </div>
    <kubernetes-connection-status
      v-if="isReconnectButtonShown"
      :configuration="configuration"
      :namespace="namespace"
      :resource-type="resourceType"
      @error="handleError"
    />
  </div>
</template>
