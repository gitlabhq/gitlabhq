<script>
import { GlButton, GlBadge, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { scrollToElement } from '~/lib/utils/common_utils';

export default {
  components: {
    GlButton,
    GlBadge,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issuesTotal: {
      type: Number,
      required: false,
      default: 0,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: null,
    },
    anchorId: {
      type: String,
      required: true,
    },
    parentScrollingId: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    buttonVariant() {
      if (this.error && !this.loading) {
        return 'danger';
      }

      return 'confirm';
    },
  },
  methods: {
    goToIssues() {
      scrollToElement(`#${this.anchorId}`, {
        parent: `#${this.parentScrollingId}`,
      });
    },
  },
};
</script>

<template>
  <gl-button
    category="tertiary"
    :variant="buttonVariant"
    button-text-classes="gl-flex gl-items-center"
    @click="goToIssues"
  >
    <span class="gl-mr-2 gl-block">{{ __('View issues') }}</span>
    <gl-loading-icon v-if="loading" size="sm" :inline="true" />
    <gl-badge
      v-else-if="error"
      v-gl-tooltip
      icon="status_warning_borderless"
      variant="danger"
      :title="s__('Observability|Failed to load related issues. Try reloading the page.')"
      data-testid="error-badge"
    />
    <gl-badge v-else variant="info" data-testid="total-badge">
      {{ issuesTotal }}
    </gl-badge>
  </gl-button>
</template>
