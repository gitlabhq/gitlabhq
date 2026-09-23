<script>
import { GlBadge, GlIcon, GlSprintf, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';

export default {
  name: 'DiscussionsBadge',
  components: { GlBadge, GlIcon, GlSprintf },
  directives: { GlTooltip },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    /**
     * Renders a subtle icon and count instead of the badge, for dense lists where a
     * coloured pill would compete with the merge request title for attention.
     */
    neutral: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    neutralText() {
      return sprintf(__('%{resolvedDiscussionsCount} of %{resolvableDiscussionsCount}'), {
        resolvedDiscussionsCount: this.mergeRequest.resolvedDiscussionsCount,
        resolvableDiscussionsCount: this.mergeRequest.resolvableDiscussionsCount,
      });
    },
    isResolved() {
      return (
        this.mergeRequest.resolvedDiscussionsCount === this.mergeRequest.resolvableDiscussionsCount
      );
    },
    badgeVariant() {
      return this.isResolved ? 'success' : 'neutral';
    },
    tooltipTitle() {
      if (this.isResolved) {
        return sprintf(
          n__(
            'The only thread is resolved',
            'All %{resolvableDiscussionsCount} threads resolved',
            this.mergeRequest.resolvableDiscussionsCount,
          ),
          {
            resolvableDiscussionsCount: this.mergeRequest.resolvableDiscussionsCount,
          },
        );
      }

      return sprintf(
        n__(
          '%{resolvedDiscussionsCount} of %{resolvableDiscussionsCount} thread resolved',
          '%{resolvedDiscussionsCount} of %{resolvableDiscussionsCount} threads resolved',
          this.mergeRequest.resolvableDiscussionsCount,
        ),
        {
          resolvedDiscussionsCount: this.mergeRequest.resolvedDiscussionsCount,
          resolvableDiscussionsCount: this.mergeRequest.resolvableDiscussionsCount,
        },
      );
    },
  },
};
</script>

<template>
  <button
    v-gl-tooltip
    :title="tooltipTitle"
    :aria-label="tooltipTitle"
    class="!gl-cursor-default gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0"
  >
    <span v-if="neutral" class="gl-flex gl-items-center gl-gap-2 gl-text-sm gl-text-subtle">
      <gl-icon name="comments" :size="12" variant="subtle" />{{ neutralText }}
    </span>
    <gl-badge v-else icon="comments" :variant="badgeVariant">
      <template v-if="isResolved">
        {{ __('Resolved') }}
      </template>
      <gl-sprintf
        v-else
        :message="__('%{resolvedDiscussionsCount} of %{resolvableDiscussionsCount}')"
      >
        <template #resolvedDiscussionsCount>{{ mergeRequest.resolvedDiscussionsCount }}</template>
        <template #resolvableDiscussionsCount>{{
          mergeRequest.resolvableDiscussionsCount
        }}</template>
      </gl-sprintf>
    </gl-badge>
  </button>
</template>
