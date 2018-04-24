<script>
import CiIcon from './ci_icon.vue';
import tooltip from '../directives/tooltip';
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
    tooltip,
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
      return className ? `ci-status ci-${className}` : 'ci-status';
    },
  },
};
</script>
<template>
  <a
    :href="status.details_path"
    :class="cssClass"
    v-tooltip
    :title="!showText ? status.text : ''"
  >
    <ci-icon :status="status" />

    <template v-if="showText">
      {{ status.text }}
    </template>
  </a>
</template>
