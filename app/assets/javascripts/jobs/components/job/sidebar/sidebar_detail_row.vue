<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  name: 'SidebarDetailRow',
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: String,
      required: true,
    },
    helpUrl: {
      type: String,
      required: false,
      default: '',
    },
    path: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasTitle() {
      return this.title.length > 0;
    },
    hasHelpURL() {
      return this.helpUrl.length > 0;
    },
  },
};
</script>
<template>
  <p class="gl-display-flex gl-justify-content-space-between gl-mb-2">
    <span v-if="hasTitle">
      <b>{{ title }}:</b>
      <gl-link
        v-if="path"
        :href="path"
        class="gl-text-blue-600!"
        data-testid="job-sidebar-value-link"
      >
        {{ value }}
      </gl-link>
      <span v-else>{{ value }}</span>
    </span>
    <gl-link v-if="hasHelpURL" :href="helpUrl" target="_blank" data-testid="job-sidebar-help-link">
      <gl-icon name="question-o" />
    </gl-link>
  </p>
</template>
