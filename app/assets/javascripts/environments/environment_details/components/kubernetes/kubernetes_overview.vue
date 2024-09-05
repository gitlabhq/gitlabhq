<script>
import {
  GlEmptyState,
  GlSprintf,
  GlLink,
  GlAlert,
  GlDrawer,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import CLUSTER_EMPTY_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-state-clusters.svg?url';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import {
  createK8sAccessConfiguration,
  fluxSyncStatus,
  updateFluxRequested,
} from '~/environments/helpers/k8s_integration_helper';
import fluxKustomizationQuery from '~/environments/graphql/queries/flux_kustomization.query.graphql';
import fluxHelmReleaseQueryStatus from '~/environments/graphql/queries/flux_helm_release.query.graphql';
import {
  CLUSTER_HEALTH_SUCCESS,
  CLUSTER_HEALTH_ERROR,
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';
import { CONNECT_MODAL_ID } from '~/clusters_list/constants';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import eventHub from '~/environments/event_hub';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import updateFluxResourceMutation from '~/environments/graphql/mutations/update_flux_resource.mutation.graphql';
import KubernetesStatusBar from './kubernetes_status_bar.vue';
import KubernetesAgentInfo from './kubernetes_agent_info.vue';
import KubernetesTabs from './kubernetes_tabs.vue';
import DeletePodModal from './delete_pod_modal.vue';

const trackingMixin = InternalEvents.mixin();

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
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    DeletePodModal,
    ConnectToAgentModal,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [trackingMixin],
  inject: ['kasTunnelUrl'],
  props: {
    environmentName: {
      type: String,
      required: true,
    },
    environmentId: {
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
      focusedElement: null,
      podToDelete: {},
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
        namespace: item.metadata.namespace,
        status: fluxSyncStatus(item.status.conditions).status,
        labels: item.metadata.labels,
        annotations: item.metadata.annotations,
        kind: item.kind,
        spec: item.spec,
        fullStatus: item.status.conditions,
        actions: [
          {
            name: 'flux-reconcile',
            text: s__('KubernetesDashboard|Trigger reconciliation'),
            icon: 'retry',
          },
        ],
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
      this.focusedElement = document.activeElement;
      this.$nextTick(() => {
        this.$refs.drawer?.$el?.querySelector('button')?.focus();
      });
    },
    closeDetailsDrawer() {
      this.showDetailsDrawer = false;
      this.selectedItem = {};
      eventHub.$emit('closeDetailsDrawer');
      this.$nextTick(() => {
        this.focusedElement?.focus();
      });
    },
    onDeletePod(pod) {
      this.podToDelete = pod;
    },
    onCloseModal() {
      this.podToDelete = {};
    },
    onFluxReconcile() {
      this.trackEvent('click_trigger_flux_reconciliation');

      this.$apollo
        .mutate({
          mutation: updateFluxResourceMutation,
          variables: {
            configuration: this.k8sAccessConfiguration,
            fluxResourcePath: this.fluxResourcePath,
            data: updateFluxRequested(),
          },
        })
        .then(({ data }) => {
          const { errors } = data.updateFluxResource;

          if (errors?.length) {
            throw new Error(errors[0]);
          } else {
            this.closeDetailsDrawer();
          }
        })
        .catch((error) => {
          createAlert({ message: this.$options.i18n.error + error.message, variant: 'danger' });
        });
    },
  },
  i18n: {
    emptyTitle: s__('Environment|No Kubernetes clusters configured'),
    emptyDescription: s__(
      'Environment|There are no Kubernetes cluster connections configured for this environment. Connect a cluster to add the status of your workloads, resources, and the Flux reconciliation state to the dashboard. %{linkStart}Learn more about Kubernetes integration.%{linkEnd}',
    ),
    emptyButton: s__('Environment|Get started'),
    connectButtonText: s__('ClusterAgents|Connect to agent'),
    actions: __('Actions'),
    error: __('Error: '),
  },
  learnMoreLink: helpPagePath('user/clusters/agent/index'),
  getStartedLink: helpPagePath('ci/environments/kubernetes_dashboard'),
  CLUSTER_EMPTY_SVG,
  DRAWER_Z_INDEX,
  CONNECT_MODAL_ID,
};
</script>
<template>
  <div v-if="clusterAgent" class="-gl-mt-3 gl-bg-gray-10 gl-p-5">
    <div class="gl-flex gl-flex-wrap gl-items-center gl-justify-between">
      <kubernetes-agent-info :cluster-agent="clusterAgent" class="gl-mb-2 gl-mr-5 gl-grow" />
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

      <gl-disclosure-dropdown
        :title="$options.i18n.actions"
        category="tertiary"
        icon="ellipsis_v"
        text-sr-only
        no-caret
      >
        <gl-disclosure-dropdown-item v-gl-modal-directive="$options.CONNECT_MODAL_ID">
          <template #list-item>
            {{ $options.i18n.connectButtonText }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>

      <connect-to-agent-modal
        :agent-id="clusterAgent.id"
        :project-path="clusterAgent.project.fullPath"
        :is-configured="true"
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
      @delete-pod="onDeletePod"
    />

    <delete-pod-modal
      :pod="podToDelete"
      :configuration="k8sAccessConfiguration"
      :agent-id="gitlabAgentId"
      :environment-id="environmentId"
      @close="onCloseModal"
    />

    <gl-drawer
      ref="drawer"
      :open="showDetailsDrawer"
      :header-height="drawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDetailsDrawer"
    >
      <template #title>
        <h2 class="gl-m-0 gl-font-bold gl-break-anywhere">
          {{ selectedItem.name }}
        </h2>
      </template>
      <template #default>
        <workload-details
          v-if="hasSelectedItem"
          :item="selectedItem"
          :configuration="k8sAccessConfiguration"
          @delete-pod="onDeletePod"
          @flux-reconcile="onFluxReconcile"
        />
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
