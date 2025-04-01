<script>
import { GlBadge, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { BADGE_METHODS } from '../utils/status_badge';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    listId: {
      type: String,
      required: true,
    },
  },
  computed: {
    currentUserId() {
      return convertToGraphQLId(TYPENAME_USER, gon.current_user_id);
    },
    currentUserAsReviewer() {
      return this.mergeRequest.reviewers.nodes.find((r) => r.id === this.currentUserId);
    },
    badgeData() {
      if (this.mergeRequest.mergeabilityChecks) {
        const failedChecks = this.mergeRequest.mergeabilityChecks.filter(
          ({ status }) => status === 'FAILED',
        );

        if (failedChecks.length === 0) {
          return {
            icon: 'status-success',
            variant: 'success',
            text: __('Ready to merge'),
            iconOpticallyAligned: true,
          };
        }
      }

      const badgeMethods = BADGE_METHODS[this.listId];

      return badgeMethods.reduce((acc, method) => {
        if (acc) return acc;

        return method(this) || acc;
      }, null);
    },
  },
};
</script>

<template>
  <gl-badge
    v-if="badgeData"
    v-gl-tooltip
    :icon="badgeData.icon"
    :variant="badgeData.variant || 'warning'"
    :title="badgeData.title"
    :icon-optically-aligned="badgeData.iconOpticallyAligned || false"
    data-testid="merge-request-status-badge"
  >
    {{ badgeData.text }}
  </gl-badge>
</template>
