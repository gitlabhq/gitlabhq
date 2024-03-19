<script>
import { GlEmptyState, GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import CLUSTER_EMPTY_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-state-clusters.svg?url';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import { createK8sAccessConfiguration } from '~/environments/helpers/k8s_integration_helper';
import { CLUSTER_HEALTH_SUCCESS, CLUSTER_HEALTH_ERROR } from '~/environments/constants';
import KubernetesStatusBar from './kubernetes_status_bar.vue';
import KubernetesAgentInfo from './kubernetes_agent_info.vue';
import KubernetesTabs from './kubernetes_tabs.vue';

export default {
  components: {
    GlEmptyState,
    KubernetesStatusBar,
    KubernetesAgentInfo,
    KubernetesTabs,
    GlSprintf,
    GlLink,
    GlAlert,
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

  data() {
    return {
      error: null,
      failedState: {},
      podsLoading: false,
      activeTab: k8sResourceType.k8sPods,
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
  },
  methods: {
    handleError(message) {
      this.error = message;
    },
    handleFailedState(event) {
      this.failedState = {
        ...this.failedState,
        ...event,
      };
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
};
</script>
<template>
  <div v-if="clusterAgent" class="gl-p-5 gl-bg-gray-10 gl-mt-n3">
    <div
      class="gl-display-flex gl-flex-wrap gl-justify-content-space-between gl-align-items-center"
    >
      <kubernetes-agent-info :cluster-agent="clusterAgent" class="gl-mb-2 gl-mr-5" />
      <kubernetes-status-bar
        :cluster-health-status="clusterHealthStatus"
        :configuration="k8sAccessConfiguration"
        :namespace="kubernetesNamespace"
        :environment-name="environmentName"
        :flux-resource-path="fluxResourcePath"
        :resource-type="activeTab"
        @error="handleError"
      />
    </div>

    <gl-alert v-if="error" variant="danger" :dismissible="false" class="gl-my-5">
      {{ error }}
    </gl-alert>

    <kubernetes-tabs
      v-model="activeTab"
      :configuration="k8sAccessConfiguration"
      :namespace="kubernetesNamespace"
      class="gl-mb-5"
      @cluster-error="handleError"
      @loading="podsLoading = $event"
      @update-failed-state="handleFailedState"
    />
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
