<script>
import { GlLoadingIcon, GlEmptyState, GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import CLUSTER_EMPTY_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-state-clusters.svg?url';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createK8sAccessConfiguration } from '~/environments/helpers/k8s_integration_helper';
import { CLUSTER_HEALTH_SUCCESS, CLUSTER_HEALTH_ERROR } from '~/environments/constants';
import environmentClusterAgentQuery from '~/environments/graphql/queries/environment_cluster_agent.query.graphql';
import KubernetesStatusBar from './kubernetes_status_bar.vue';
import KubernetesAgentInfo from './kubernetes_agent_info.vue';
import KubernetesTabs from './kubernetes_tabs.vue';

export default {
  components: {
    GlLoadingIcon,
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
    projectFullPath: {
      type: String,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
  },
  apollo: {
    environment: {
      query: environmentClusterAgentQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          environmentName: this.environmentName,
        };
      },
      update(data) {
        return data?.project?.environment;
      },
    },
  },
  data() {
    return {
      error: null,
      failedState: {},
      podsLoading: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.environment.loading;
    },
    clusterAgent() {
      return this.environment?.clusterAgent;
    },
    kubernetesNamespace() {
      return this.environment?.kubernetesNamespace || '';
    },
    fluxResourcePath() {
      return this.environment?.fluxResourcePath || '';
    },
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
    handleClusterError(message) {
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
  <gl-loading-icon v-if="isLoading" />
  <div v-else-if="clusterAgent" class="gl-p-5 gl-bg-gray-10 gl-mt-n3">
    <div
      class="gl-display-flex gl-flex-wrap gl-justify-content-space-between gl-align-items-center"
    >
      <kubernetes-agent-info :cluster-agent="clusterAgent" class="gl-mb-2 gl-mr-5" />
      <kubernetes-status-bar
        :cluster-health-status="clusterHealthStatus"
        :configuration="k8sAccessConfiguration"
        :environment-name="environmentName"
        :flux-resource-path="fluxResourcePath"
      />
    </div>

    <gl-alert v-if="error" variant="danger" :dismissible="false" class="gl-my-5">
      {{ error }}
    </gl-alert>

    <kubernetes-tabs
      :configuration="k8sAccessConfiguration"
      :namespace="kubernetesNamespace"
      class="gl-mb-5"
      @cluster-error="handleClusterError"
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
