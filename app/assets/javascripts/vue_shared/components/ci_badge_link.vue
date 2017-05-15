<script>
import ciIcon from './ci_icon.vue';
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
 * Shared between:
 * - Pipelines table - first column
 * - Jobs table - first column
 * - Pipeline show view - header
 * - Job show view - header
 * - MR widget
 */

export default {
  props: {
    status: {
      type: Object,
      required: true,
    },
  },

  components: {
    ciIcon,
  },

  computed: {
    cssClass() {
      const className = this.status.group;

      return className ? `ci-status ci-${this.status.group}` : 'ci-status';
    },
  },
};
</script>
<template>
  <a
    :href="status.details_path"
    :class="cssClass">
    <ci-icon :status="status" />
    {{status.text}}
  </a>
</template>
