<script>
import { GlEmptyState, GlSprintf, GlLink, GlAlert, GlDrawer } from '@gitlab/ui';
import CLUSTER_EMPTY_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-state-clusters.svg?url';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import {
  createK8sAccessConfiguration,
  fluxSyncStatus,
} from '~/environments/helpers/k8s_integration_helper';
import fluxKustomizationQuery from '~/environments/graphql/queries/flux_kustomization.query.graphql';
import fluxHelmReleaseQueryStatus from '~/environments/graphql/queries/flux_helm_release.query.graphql';
import {
  CLUSTER_HEALTH_SUCCESS,
  CLUSTER_HEALTH_ERROR,
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import KubernetesStatusBar from './kubernetes_status_bar.vue';
import KubernetesAgentInfo from './kubernetes_agent_info.vue';
import KubernetesTabs from './kubernetes_tabs.vue';

export default {
  components: {
    GlEmptyState,
    KubernetesStatusBar,
    KubernetesAgentInfo,
    KubernetesTabs,
    WorkloadDetails,
    GlSprintf,
    GlLink,
    GlAlert,
    GlDrawer,
  },
  inject: ['kasTunnelUrl'],
  props: {
    environmentName: {
      type: String,
      required: true,
    },
    clusterAgent: {
      type: Object,
      required: false,
      default: null,
    },
    kubernetesNamespace: {
      type: String,
      required: false,
      default: '',
    },
    fluxResourcePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    fluxKustomization: {
      query: fluxKustomizationQuery,
      variables() {
        return {
          configuration: this.k8sAccessConfiguration,
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
    fluxHelmRelease: {
      query: fluxHelmReleaseQueryStatus,
      variables() {
        return {
          configuration: this.k8sAccessConfiguration,
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
      error: null,
      failedState: {},
      podsLoading: false,
      activeTab: k8sResourceType.k8sPods,
      fluxApiError: '',
      selectedItem: {},
      showDetailsDrawer: false,
    };
  },
  computed: {
    gitlabAgentId() {
      return getIdFromGraphQLId(this.clusterAgent.id).toString();
    },
    k8sAccessConfiguration() {
      return createK8sAccessConfiguration({
        kasTunnelUrl: this.kasTunnelUrl,
        gitlabAgentId: this.gitlabAgentId,
      });
    },
    clusterHealthStatus() {
      if (this.podsLoading) {
        return '';
      }
      return this.hasFailedState ? CLUSTER_HEALTH_ERROR : CLUSTER_HEALTH_SUCCESS;
    },
    hasFailedState() {
      return Object.values(this.failedState).some((item) => item);
    },
    fluxResourceStatus() {
      return this.fluxKustomization?.conditions || this.fluxHelmRelease?.conditions;
    },
    drawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    hasSelectedItem() {
      return Object.keys(this.selectedItem).length;
    },
  },
  methods: {
    handleError(message) {
      Sentry.captureException(message, {
        tags: {
          vue_component: 'KubernetesOverview',
        },
      });
      this.error = message;
    },
    handleFailedState(event) {
      this.failedState = {
        ...this.failedState,
        ...event,
      };
    },
    transformFluxResourceData(item) {
      return {
        name: item.metadata.name,
        status: fluxSyncStatus(item.status.conditions).status,
        labels: item.metadata.labels,
        annotations: item.metadata.annotations,
        kind: item.kind,
        spec: item.spec,
        fullStatus: item.status.conditions,
      };
    },
    showFluxResourceDetails() {
      const fluxResource = this.fluxKustomization || this.fluxHelmRelease;
      const fluxResourceTransformed = this.transformFluxResourceData(fluxResource);

      this.openDetailsDrawer(fluxResourceTransformed);
    },
    openDetailsDrawer(item) {
      this.selectedItem = item;
      this.showDetailsDrawer = true;
      this.$nextTick(() => {
        this.$refs.drawer?.$el?.querySelector('button')?.focus();
      });
    },
    closeDetailsDrawer() {
      this.showDetailsDrawer = false;
      this.selectedItem = {};
      this.$nextTick(() => {
        this.$refs.status_bar?.$refs?.flux_status_badge?.$el?.focus();
      });
    },
  },
  i18n: {
    emptyTitle: s__('Environment|No Kubernetes clusters configured'),
    emptyDescription: s__(
      'Environment|There are no Kubernetes cluster connections configured for this environment. Connect a cluster to add the status of your workloads, resources, and the Flux reconciliation state to the dashboard. %{linkStart}Learn more about Kubernetes integration.%{linkEnd}',
    ),
    emptyButton: s__('Environment|Get started'),
  },
  learnMoreLink: helpPagePath('user/clusters/agent/index'),
  getStartedLink: helpPagePath('ci/environments/kubernetes_dashboard'),
  CLUSTER_EMPTY_SVG,
  DRAWER_Z_INDEX,
};
</script>
<template>
  <div v-if="clusterAgent" class="gl-p-5 gl-bg-gray-10 -gl-mt-3">
    <div
      class="gl-display-flex gl-flex-wrap gl-justify-content-space-between gl-align-items-center"
    >
      <kubernetes-agent-info :cluster-agent="clusterAgent" class="gl-mb-2 gl-mr-5" />
      <kubernetes-status-bar
        ref="status_bar"
        :cluster-health-status="clusterHealthStatus"
        :configuration="k8sAccessConfiguration"
        :namespace="kubernetesNamespace"
        :environment-name="environmentName"
        :flux-resource-path="fluxResourcePath"
        :resource-type="activeTab"
        :flux-resource-status="fluxResourceStatus"
        :flux-api-error="fluxApiError"
        @error="handleError"
        @show-flux-resource-details="showFluxResourceDetails"
      />
    </div>

    <gl-alert v-if="error" variant="danger" :dismissible="false" class="gl-my-5">
      {{ error }}
    </gl-alert>
    <kubernetes-tabs
      v-model="activeTab"
      :configuration="k8sAccessConfiguration"
      :namespace="kubernetesNamespace"
      :flux-kustomization="fluxKustomization"
      class="gl-mb-5"
      @cluster-error="handleError"
      @loading="podsLoading = $event"
      @update-failed-state="handleFailedState"
      @show-resource-details="openDetailsDrawer"
      @remove-selection="closeDetailsDrawer"
    />

    <gl-drawer
      ref="drawer"
      :open="showDetailsDrawer"
      :header-height="drawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDetailsDrawer"
    >
      <template #title>
        <h2 class="gl-font-bold gl-m-0 gl-break-anywhere">
          {{ selectedItem.name }}
        </h2>
      </template>
      <template #default>
        <workload-details v-if="hasSelectedItem" :item="selectedItem" />
      </template>
    </gl-drawer>
  </div>
  <gl-empty-state
    v-else
    :title="$options.i18n.emptyTitle"
    :primary-button-text="$options.i18n.emptyButton"
    :primary-button-link="$options.getStartedLink"
    :svg-path="$options.CLUSTER_EMPTY_SVG"
  >
    <template #description>
      <gl-sprintf :message="$options.i18n.emptyDescription">
        <template #link="{ content }">
          <gl-link :href="$options.learnMoreLink">{{ content }}</gl-link>
        </template></gl-sprintf
      >
    </template>
  </gl-empty-state>
</template>
