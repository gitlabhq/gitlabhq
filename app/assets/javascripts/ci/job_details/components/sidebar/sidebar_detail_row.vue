<script>
import { GlLink } from '@gitlab/ui';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';

export default {
  name: 'SidebarDetailRow',
  components: {
    GlLink,
    HelpIcon,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    headingTag: {
      type: String,
      required: false,
      default: 'span',
      validator: (value) => value === null || ['span', 'h2', 'h3', 'h4', 'h5'].includes(value),
    },
    value: {
      type: String,
      required: false,
      default: null,
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
  <p class="build-sidebar-item gl-flex gl-flex-col gl-gap-3 gl-leading-normal">
    <component
      :is="headingTag"
      v-if="hasTitle"
      class="gl-my-0 gl-mr-3 gl-text-md gl-font-bold"
      data-testid="job-sidebar-value-title"
      >{{ title }}</component
    >
    <gl-link v-if="path" :href="path" class="!gl-text-link" data-testid="job-sidebar-value-link">
      {{ value }}
    </gl-link>
    <span v-else class="gl-text-subtle" data-testid="job-sidebar-value-span"
      >{{ value }}
      <slot></slot>
      <gl-link
        v-if="hasHelpURL"
        :aria-label="s__('Job|Job help')"
        :href="helpUrl"
        target="_blank"
        data-testid="job-sidebar-help-link"
      >
        <help-icon class="gl-ml-2" />
      </gl-link>
    </span>
  </p>
</template>
