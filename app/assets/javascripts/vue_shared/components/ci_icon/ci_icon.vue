<script>
import { GlBadge, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

/**
 * Renders CI icon based on API response shared between all places where it is used.
 *
 * Receives status object containing:
 * status: {
 *   icon: "status_running" // used to render the icon and CSS class
 *   text: "Running",
 *   detailsPath: '/project1/jobs/1' // can also be details_path
 * }
 *
 * You may use ~/graphql_shared/fragments/ci_icon.fragment.graphql to fetch this
 * from the GraphQL API.
 *
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
        const { icon } = status;
        return typeof icon === 'string' && icon.startsWith('status_');
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
      if (this.showTooltip) {
        // show tooltip only when not showing text already
        return !this.showStatusText ? this.status?.text : null;
      }
      return null;
    },
    ariaLabel() {
      return sprintf(__('Status: %{status}'), { status: this.status?.text });
    },
    href() {
      // href can come from GraphQL (camelCase) or REST API (snake_case)
      if (this.useLink) {
        return this.status.detailsPath || this.status.details_path;
      }
      return null;
    },
    icon() {
      if (this.status.icon) {
        return `${this.status.icon}_borderless`;
      }
      return null;
    },
    variant() {
      switch (this.status.icon) {
        case 'status_success':
          return 'success';
        case 'status_warning':
        case 'status_pending':
          return 'warning';
        case 'status_failed':
          return 'danger';
        case 'status_running':
          return 'info';
        // default covers the styles for the remainder of CI
        // statuses that are not explicitly stated here
        default:
          return 'neutral';
      }
    },
  },
};
</script>
<template>
  <gl-badge
    v-gl-tooltip
    class="ci-icon gl-p-2"
    :class="`ci-icon-variant-${variant}`"
    :variant="variant"
    :title="title"
    :aria-label="ariaLabel"
    :href="href"
    size="md"
    data-testid="ci-icon"
    @click="$emit('ciStatusBadgeClick')"
  >
    <span class="ci-icon-gl-icon-wrapper"><gl-icon :name="icon" /></span
    ><span v-if="showStatusText" class="gl-mx-2 gl-white-space-nowrap" data-testid="ci-icon-text">{{
      status.text
    }}</span>
  </gl-badge>
</template>
