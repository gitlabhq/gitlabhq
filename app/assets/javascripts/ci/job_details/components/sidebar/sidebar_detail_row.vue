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
  <p class="build-sidebar-item gl-line-height-normal gl-display-flex gl-mb-3">
    <b v-if="hasTitle" class="gl-mr-3">{{ title }}:</b>
    <gl-link
      v-if="path"
      :href="path"
      class="gl-text-blue-600!"
      data-testid="job-sidebar-value-link"
    >
      {{ value }}
    </gl-link>
    <span v-else
      >{{ value }}
      <gl-link
        v-if="hasHelpURL"
        :href="helpUrl"
        target="_blank"
        data-testid="job-sidebar-help-link"
      >
        <gl-icon name="question-o" class="gl-ml-2 gl-text-blue-500" />
      </gl-link>
    </span>
  </p>
</template>
