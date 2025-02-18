<script>
import { GlBadge, GlSprintf, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';

export default {
  components: { GlBadge, GlSprintf },
  directives: { GlTooltip },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isResolved() {
      return (
        this.mergeRequest.resolvedDiscussionsCount === this.mergeRequest.resolvableDiscussionsCount
      );
    },
    badgeVariant() {
      return this.isResolved ? 'success' : 'muted';
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
  <gl-badge v-gl-tooltip :title="tooltipTitle" icon="comments" :variant="badgeVariant">
    <template v-if="isResolved">
      {{ __('Resolved') }}
    </template>
    <gl-sprintf
      v-else
      :message="__('%{resolvedDiscussionsCount} of %{resolvableDiscussionsCount}')"
    >
      <template #resolvedDiscussionsCount>{{ mergeRequest.resolvedDiscussionsCount }}</template>
      <template #resolvableDiscussionsCount>{{ mergeRequest.resolvableDiscussionsCount }}</template>
    </gl-sprintf>
  </gl-badge>
</template>
