<script>
import { GlLoadingIcon, GlAlert, GlEmptyState, GlSprintf, GlIcon } from '@gitlab/ui';
import EmptyStateSvg from '@gitlab/svgs/dist/illustrations/status/status-nothing-md.svg';
import k8sLogsQuery from '~/environments/graphql/queries/k8s_logs.query.graphql';
import environmentClusterAgentQuery from '~/environments/graphql/queries/environment_cluster_agent.query.graphql';
import abortK8sPodLogsStream from '~/environments/graphql/mutations/abort_pod_logs_stream.mutation.graphql';
import { createK8sAccessConfiguration } from '~/environments/helpers/k8s_integration_helper';
import LogsViewer from '~/vue_shared/components/logs_viewer/logs_viewer.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__, __ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';

export default {
  components: {
    LogsViewer,
    GlLoadingIcon,
    GlAlert,
    GlEmptyState,
    GlSprintf,
    GlIcon,
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
      k8sLogs: null,
      environment: null,
    };
  },
  apollo: {
    k8sLogs: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
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
    headerData() {
      const data = [
        {
          icon: 'kubernetes-agent',
          label: this.$options.i18n.agent,
          value: this.gitlabAgentId,
        },
        { icon: 'namespace', label: this.$options.i18n.namespace, value: this.namespace },
        { icon: 'pod', label: this.$options.i18n.pod, value: this.podName },
      ];
      const containerData = {
        icon: 'container-image',
        label: this.$options.i18n.container,
        value: this.containerName,
      };
      if (this.containerName) data.push(containerData);
      return data;
    },
  },
  beforeDestroy() {
    this.$apollo.mutate({
      mutation: abortK8sPodLogsStream,
      variables: {
        configuration: this.k8sAccessConfiguration,
        namespace: this.namespace,
        podName: this.podName,
        containerName: this.containerName,
      },
    });
  },
  i18n: {
    emptyStateTitleForPod: s__('KubernetesLogs|No logs available for pod %{podName}'),
    emptyStateTitleForContainer: s__(
      'KubernetesLogs|No logs available for container %{containerName} of pod %{podName}',
    ),
    agent: s__('KubernetesLogs|Agent ID'),
    pod: s__('KubernetesLogs|Pod'),
    container: s__('KubernetesLogs|Container'),
    namespace: s__('KubernetesLogs|Namespace'),
    error: __('Error'),
  },
  EmptyStateSvg,
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" :dismissible="false"
      >{{ $options.i18n.error }}: {{ error }}</gl-alert
    >
    <gl-loading-icon v-if="isLoading" />

    <logs-viewer v-else-if="logLines" :log-lines="logLines" :highlighted-line="highlightedLineHash"
      ><template #header-details
        ><div class="gl-ml-auto gl-p-3">
          <span v-for="(item, index) of headerData" :key="index" class="gl-mr-4">
            <gl-icon :name="item.icon" class="gl-mr-2" />{{ item.label }}: {{ item.value }}</span
          >
        </div>
      </template>
    </logs-viewer>
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
