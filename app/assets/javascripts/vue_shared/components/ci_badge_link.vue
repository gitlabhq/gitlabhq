<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
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

const badgeSizeOptions = {
  sm: 'sm',
  md: 'md',
  lg: 'lg',
};

export default {
  components: {
    CiIcon,
    GlBadge,
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
    badgeSize: {
      type: String,
      required: false,
      default: badgeSizeOptions.md,
      validator(value) {
        return badgeSizeOptions[value] !== undefined;
      },
    },
  },
  computed: {
    isSmallBadgeSize() {
      return this.badgeSize === badgeSizeOptions.sm;
    },
    title() {
      return !this.showText ? this.status?.text : '';
    },
    detailsPath() {
      // For now, this can either come from graphQL with camelCase or REST API in snake_case
      return this.status.detailsPath || this.status.details_path;
    },
    badgeStyles() {
      switch (this.status.icon) {
        case 'status_success':
          return {
            textColor: 'gl-text-green-700',
            variant: 'success',
          };
        case 'status_warning':
          return {
            textColor: 'gl-text-orange-700',
            variant: 'warning',
          };
        case 'status_failed':
          return {
            textColor: 'gl-text-red-700',
            variant: 'danger',
          };
        case 'status_running':
          return {
            textColor: 'gl-text-blue-700',
            variant: 'info',
          };
        case 'status_pending':
          return {
            textColor: 'gl-text-orange-700',
            variant: 'warning',
          };
        case 'status_canceled':
          return {
            textColor: 'gl-text-gray-700',
            variant: 'neutral',
          };
        case 'status_manual':
          return {
            textColor: 'gl-text-gray-700',
            variant: 'neutral',
          };
        // default covers the styles for the remainder of CI
        // statuses that are not explicitly stated here
        default:
          return {
            textColor: 'gl-text-gray-600',
            variant: 'muted',
          };
      }
    },
  },
};
</script>
<template>
  <gl-badge
    v-gl-tooltip
    :class="{ 'gl-pl-0!': isSmallBadgeSize }"
    :title="title"
    :href="detailsPath"
    :size="badgeSize"
    :variant="badgeStyles.variant"
    data-testid="ci-badge-link"
    data-qa-selector="status_badge_link"
    @click="$emit('ciStatusBadgeClick')"
  >
    <ci-icon :status="status" />

    <template v-if="showText">
      <span
        class="gl-ml-2 gl-white-space-nowrap"
        :class="badgeStyles.textColor"
        data-testid="ci-badge-text"
      >
        {{ status.text }}
      </span>
    </template>
  </gl-badge>
</template>
