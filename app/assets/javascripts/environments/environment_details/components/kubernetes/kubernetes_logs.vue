<script>
import { GlLoadingIcon, GlAlert, GlEmptyState, GlSprintf } from '@gitlab/ui';
import EmptyStateSvg from '@gitlab/svgs/dist/illustrations/Dependency-list-empty-state.svg?url';
import k8sLogsQuery from '~/environments/graphql/queries/k8s_logs.query.graphql';
import environmentClusterAgentQuery from '~/environments/graphql/queries/environment_cluster_agent.query.graphql';
import { createK8sAccessConfiguration } from '~/environments/helpers/k8s_integration_helper';
import LogsViewer from '~/vue_shared/components/logs_viewer/logs_viewer.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';

export default {
  components: {
    LogsViewer,
    GlLoadingIcon,
    GlAlert,
    GlEmptyState,
    GlSprintf,
  },
  inject: ['kasTunnelUrl', 'projectPath'],
  props: {
    podName: {
      type: String,
      required: true,
    },
    containerName: {
      type: String,
      required: false,
      default: '',
    },
    namespace: {
      type: String,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
    highlightedLineHash: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      environmentError: null,
    };
  },
  apollo: {
    k8sLogs: {
      query: k8sLogsQuery,
      variables() {
        return {
          configuration: this.k8sAccessConfiguration,
          namespace: this.namespace,
          podName: this.podName,
          containerName: this.containerName,
        };
      },
      skip() {
        return Boolean(!this.gitlabAgentId);
      },
    },
    environment: {
      query: environmentClusterAgentQuery,
      variables() {
        return {
          projectFullPath: this.projectPath,
          environmentName: this.environmentName,
        };
      },
      update(data) {
        this.environmentError = null;
        return data?.project?.environment;
      },
      error(error) {
        this.environmentError = error;
      },
    },
  },
  computed: {
    error() {
      return this.k8sLogs?.error?.message || this.environmentError?.message;
    },
    gitlabAgentId() {
      return (
        this.environment?.clusterAgent?.id &&
        getIdFromGraphQLId(this.environment.clusterAgent.id).toString()
      );
    },
    k8sAccessConfiguration() {
      return createK8sAccessConfiguration({
        kasTunnelUrl: this.kasTunnelUrl,
        gitlabAgentId: this.gitlabAgentId,
      });
    },
    logLines() {
      return this.k8sLogs?.logs?.map((log) => ({
        content: [{ text: log.content }],
        lineNumber: log.id,
        lineId: `L${log.id}`,
      }));
    },
    isLoading() {
      return this.$apollo.queries.k8sLogs.loading || this.$apollo.queries.environment.loading;
    },
    emptyStateTitle() {
      return this.containerName
        ? this.$options.i18n.emptyStateTitleForContainer
        : this.$options.i18n.emptyStateTitleForPod;
    },
  },
  i18n: {
    emptyStateTitleForPod: s__('KubernetesLogs|No logs available for pod %{podName}'),
    emptyStateTitleForContainer: s__(
      'KubernetesLogs|No logs available for container %{containerName} of pod %{podName}',
    ),
  },
  EmptyStateSvg,
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" :dismissible="false">{{ error }}</gl-alert>
    <gl-loading-icon v-if="isLoading" />
    <logs-viewer
      v-else-if="logLines"
      :log-lines="logLines"
      :highlighted-line="highlightedLineHash"
    />
    <gl-empty-state v-else :svg-path="$options.EmptyStateSvg">
      <template #title>
        <h3>
          <gl-sprintf :message="emptyStateTitle"
            ><template #podName>{{ podName }}</template
            ><template #containerName>{{ containerName }}</template>
          </gl-sprintf>
        </h3>
      </template>
    </gl-empty-state>
  </div>
</template>
