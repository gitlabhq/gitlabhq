<script>
import { GlCollapse, GlButton, GlAlert } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import KubernetesAgentInfo from './kubernetes_agent_info.vue';
import KubernetesPods from './kubernetes_pods.vue';
import KubernetesTabs from './kubernetes_tabs.vue';

export default {
  components: {
    GlCollapse,
    GlButton,
    GlAlert,
    KubernetesAgentInfo,
    KubernetesPods,
    KubernetesTabs,
  },
  inject: ['kasTunnelUrl'],
  props: {
    agentName: {
      required: true,
      type: String,
    },
    agentId: {
      required: true,
      type: String,
    },
    agentProjectPath: {
      required: true,
      type: String,
    },
    namespace: {
      required: false,
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isVisible: false,
      error: '',
    };
  },
  computed: {
    chevronIcon() {
      return this.isVisible ? 'chevron-down' : 'chevron-right';
    },
    label() {
      return this.isVisible ? this.$options.i18n.collapse : this.$options.i18n.expand;
    },
    gitlabAgentId() {
      const id = isGid(this.agentId) ? getIdFromGraphQLId(this.agentId) : this.agentId;
      return id.toString();
    },
    k8sAccessConfiguration() {
      return {
        basePath: this.kasTunnelUrl,
        baseOptions: {
          headers: { 'GitLab-Agent-Id': this.gitlabAgentId, ...csrf.headers },
        },
      };
    },
  },
  methods: {
    toggleCollapse() {
      this.isVisible = !this.isVisible;
    },
    onClusterError(message) {
      this.error = message;
    },
  },
  i18n: {
    collapse: __('Collapse'),
    expand: __('Expand'),
    sectionTitle: s__('Environment|Kubernetes overview'),
  },
};
</script>
<template>
  <div class="gl-px-4">
    <p class="gl-font-weight-bold gl-text-gray-500 gl-display-flex gl-mb-0">
      <gl-button
        :icon="chevronIcon"
        :aria-label="label"
        category="tertiary"
        size="small"
        class="gl-mr-3"
        @click="toggleCollapse"
      />{{ $options.i18n.sectionTitle }}
    </p>
    <gl-collapse :visible="isVisible" class="gl-md-pl-7 gl-md-pr-5 gl-mt-4">
      <template v-if="isVisible">
        <kubernetes-agent-info
          :agent-name="agentName"
          :agent-id="agentId"
          :agent-project-path="agentProjectPath"
          class="gl-mb-5" />

        <gl-alert v-if="error" variant="danger" :dismissible="false" class="gl-mb-5">
          {{ error }}
        </gl-alert>

        <kubernetes-pods
          :configuration="k8sAccessConfiguration"
          :namespace="namespace"
          class="gl-mb-5"
          @cluster-error="onClusterError" />
        <kubernetes-tabs
          :configuration="k8sAccessConfiguration"
          :namespace="namespace"
          class="gl-mb-5"
          @cluster-error="onClusterError"
      /></template>
    </gl-collapse>
  </div>
</template>
