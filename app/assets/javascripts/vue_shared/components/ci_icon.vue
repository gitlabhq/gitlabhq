<script>
import { GlBadge, GlTooltipDirective, GlIcon } from '@gitlab/ui';

/**
 * Renders CI icon based on API response shared between all places where it is used.
 *
 * Receives status object containing:
 * status: {
 *   group:"running" // used for CSS class
 *   icon: "icon_status_running" // used to render the icon
 * }
 *
 * Used in:
 * - Extended MR Popover
 * - Jobs show view header
 * - Jobs show view sidebar
 * - Jobs table
 * - Linked pipelines
 * - Pipeline graph
 * - Pipeline mini graph
 * - Pipeline show view badge
 * - Pipelines table Badge
 */

export default {
  components: {
    GlBadge,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    status: {
      type: Object,
      required: true,
      validator(status) {
        const { group, icon } = status;
        return (
          typeof group === 'string' &&
          group.length &&
          typeof icon === 'string' &&
          icon.startsWith('status_')
        );
      },
    },
    showStatusText: {
      type: Boolean,
      required: false,
      default: false,
    },
    showTooltip: {
      type: Boolean,
      required: false,
      default: true,
    },
    useLink: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  computed: {
    title() {
      return this.showTooltip && !this.showStatusText ? this.status?.text : '';
    },
    detailsPath() {
      // For now, this can either come from graphQL with camelCase or REST API in snake_case
      if (!this.useLink) {
        return null;
      }
      return this.status.detailsPath || this.status.details_path;
    },
    wrapperStyleClasses() {
      const status = this.status.group;
      return `ci-status-icon ci-status-icon-${status} gl-rounded-full gl-justify-content-center gl-line-height-0`;
    },
    icon() {
      return this.status.icon;
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
    class="ci-icon gl-p-2"
    :title="title"
    :aria-label="title"
    :href="detailsPath"
    size="md"
    :variant="badgeStyles.variant"
    data-testid="ci-icon"
    @click="$emit('ciStatusBadgeClick')"
  >
    <span
      class="ci-icon-wrapper"
      :class="[
        wrapperStyleClasses,
        {
          'gl-display-inline-block gl-vertical-align-top': showStatusText,
        },
      ]"
    >
      <gl-icon :name="icon" :aria-label="status.icon" /> </span
    ><span
      v-if="showStatusText"
      class="gl-mx-2 gl-white-space-nowrap"
      :class="badgeStyles.textColor"
      data-testid="ci-icon-text"
      >{{ status.text }}</span
    >
  </gl-badge>
</template>
