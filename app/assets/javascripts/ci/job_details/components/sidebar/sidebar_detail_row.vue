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
  <p class="build-sidebar-item gl-mb-3 gl-flex gl-leading-normal">
    <b v-if="hasTitle" class="gl-mr-3">{{ title }}:</b>
    <gl-link v-if="path" :href="path" class="!gl-text-link" data-testid="job-sidebar-value-link">
      {{ value }}
    </gl-link>
    <span v-else class="gl-text-subtle"
      >{{ value }}
      <gl-link
        v-if="hasHelpURL"
        :href="helpUrl"
        target="_blank"
        data-testid="job-sidebar-help-link"
      >
        <help-icon class="gl-ml-2" />
      </gl-link>
    </span>
  </p>
</template>
