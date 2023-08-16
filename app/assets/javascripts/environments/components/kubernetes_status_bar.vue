<script>
import { GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  HEALTH_BADGES,
  SYNC_STATUS_BADGES,
  STATUS_TRUE,
  STATUS_FALSE,
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '../constants';
import fluxKustomizationStatusQuery from '../graphql/queries/flux_kustomization_status.query.graphql';
import fluxHelmReleaseStatusQuery from '../graphql/queries/flux_helm_release_status.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlBadge,
  },
  props: {
    clusterHealthStatus: {
      required: false,
      type: String,
      default: '',
      validator(val) {
        return ['error', 'success', ''].includes(val);
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
      required: false,
      type: String,
      default: '',
    },
    fluxResourcePath: {
      required: false,
      type: String,
      default: '',
    },
  },
  apollo: {
    fluxKustomizationStatus: {
      query: fluxKustomizationStatusQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
          environmentName: this.environmentName.toLowerCase(),
          fluxResourcePath: this.fluxResourcePath,
        };
      },
      skip() {
        return Boolean(
          !this.namespace || this.fluxResourcePath?.includes(HELM_RELEASES_RESOURCE_TYPE),
        );
      },
    },
    fluxHelmReleaseStatus: {
      query: fluxHelmReleaseStatusQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
          environmentName: this.environmentName.toLowerCase(),
          fluxResourcePath: this.fluxResourcePath,
        };
      },
      skip() {
        return Boolean(
          !this.namespace ||
            this.$apollo.queries.fluxKustomizationStatus.loading ||
            this.hasKustomizations ||
            this.fluxResourcePath?.includes(KUSTOMIZATIONS_RESOURCE_TYPE),
        );
      },
    },
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
      if (!this.fluxCRD.length) {
        return SYNC_STATUS_BADGES.unavailable;
      } else if (this.fluxAnyFailed) {
        return SYNC_STATUS_BADGES.failed;
      } else if (this.fluxAnyStalled) {
        return SYNC_STATUS_BADGES.stalled;
      } else if (this.fluxAnyReconciling) {
        return SYNC_STATUS_BADGES.reconciling;
      } else if (this.fluxAnyReconciled) {
        return SYNC_STATUS_BADGES.reconciled;
      }
      return SYNC_STATUS_BADGES.unknown;
    },
  },
  i18n: {
    healthLabel: s__('Environment|Environment health'),
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
      <gl-badge v-else-if="healthBadge" :variant="healthBadge.variant" data-testid="health-badge">
        {{ healthBadge.text }}
      </gl-badge>
    </div>

    <div :class="$options.badgeContainerClasses">
      <span class="gl-mr-3">{{ $options.i18n.syncStatusLabel }}</span>
      <gl-loading-icon v-if="isLoading" size="sm" inline />
      <gl-badge
        v-else-if="syncStatusBadge"
        :icon="syncStatusBadge.icon"
        :variant="syncStatusBadge.variant"
        data-testid="sync-badge"
        >{{ syncStatusBadge.text }}</gl-badge
      >
    </div>
  </div>
</template>
