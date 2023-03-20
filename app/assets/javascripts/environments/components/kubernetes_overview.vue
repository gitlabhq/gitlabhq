<script>
import { GlCollapse, GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import KubernetesAgentInfo from './kubernetes_agent_info.vue';

export default {
  components: {
    GlCollapse,
    GlButton,
    KubernetesAgentInfo,
  },
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
  },
  data() {
    return {
      isVisible: false,
    };
  },
  computed: {
    chevronIcon() {
      return this.isVisible ? 'chevron-down' : 'chevron-right';
    },
    label() {
      return this.isVisible ? this.$options.i18n.collapse : this.$options.i18n.expand;
    },
  },
  methods: {
    toggleCollapse() {
      this.isVisible = !this.isVisible;
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
          class="gl-mb-5"
      /></template>
    </gl-collapse>
  </div>
</template>
