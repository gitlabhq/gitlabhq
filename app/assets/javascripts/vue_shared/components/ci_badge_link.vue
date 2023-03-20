<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import CiIcon from './ci_icon.vue';
/**
 * Renders CI Badge link with CI icon and status text based on
 * API response shared between all places where it is used.
 *
 * Receives status object containing:
 * status: {
 *   details_path or detailsPath: "/gitlab-org/gitlab-foss/pipelines/8150156" // url
 *   group:"running" // used for CSS class
 *   icon: "icon_status_running" // used to render the icon
 *   label:"running" // used for potential tooltip
 *   text:"running" // text rendered
 * }
 *
 * Used in:
 * - Pipelines table - first column
 * - Jobs table - first column
 * - Pipeline show view - header
 * - Job show view - header
 * - MR widget
 * - Terraform table
 * - On-demand scans list
 */

export default {
  components: {
    GlLink,
    CiIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    status: {
      type: Object,
      required: true,
    },
    showText: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    title() {
      return !this.showText ? this.status?.text : '';
    },
    detailsPath() {
      // For now, this can either come from graphQL with camelCase or REST API in snake_case
      return this.status.detailsPath || this.status.details_path;
    },
    cssClass() {
      const className = this.status.group;
      return className ? `ci-status ci-${className}` : 'ci-status';
    },
  },
};
</script>
<template>
  <gl-link
    v-gl-tooltip
    class="gl-display-inline-flex gl-align-items-center gl-line-height-0 gl-px-3 gl-py-2 gl-rounded-base"
    :class="cssClass"
    :title="title"
    data-qa-selector="status_badge_link"
    :href="detailsPath"
    @click="$emit('ciStatusBadgeClick')"
  >
    <ci-icon :status="status" />

    <template v-if="showText">
      <span class="gl-ml-2 gl-white-space-nowrap">{{ status.text }}</span>
    </template>
  </gl-link>
</template>
