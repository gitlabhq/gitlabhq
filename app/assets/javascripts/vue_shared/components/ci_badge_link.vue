<script>
import { GlTooltipDirective } from '@gitlab/ui';
import CiIcon from './ci_icon.vue';
/**
 * Renders CI Badge link with CI icon and status text based on
 * API response shared between all places where it is used.
 *
 * Receives status object containing:
 * status: {
 *   details_path: "/gitlab-org/gitlab-ce/pipelines/8150156" // url
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
 */

export default {
  components: {
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
    cssClass() {
      const className = this.status.group;
      return className ? `ci-status ci-${className} qa-status-badge` : 'ci-status qa-status-badge';
    },
  },
};
</script>
<template>
  <a
    v-gl-tooltip
    :href="status.details_path"
    :class="cssClass"
    :title="!showText ? status.text : ''"
  >
    <ci-icon :status="status" />

    <template v-if="showText">
      {{ status.text }}
    </template>
  </a>
</template>
