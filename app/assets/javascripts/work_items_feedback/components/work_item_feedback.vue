<script>
import { GlBadge, GlPopover, GlLink } from '@gitlab/ui';
import { uniqueId } from 'lodash';

import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  name: 'WorkItemFeedback',
  components: {
    GlBadge,
    GlPopover,
    GlLink,
    UserCalloutDismisser,
  },
  inject: [
    'feedbackIssue',
    'feedbackIssueText',
    'featureName',
    'badgeTitle',
    'badgePopoverTitle',
    'badgeContent',
  ],
  badgeId: uniqueId(),
};
</script>

<template>
  <div class="gl-hidden gl-content-center sm:gl-flex" data-testid="work-item-feedback">
    <gl-badge :id="$options.badgeId" variant="info" icon="information-o" href="#">{{
      badgeTitle
    }}</gl-badge>
    <user-callout-dismisser :feature-name="featureName">
      <template #default="{ dismiss, shouldShowCallout }">
        <gl-popover
          :target="$options.badgeId"
          :show="shouldShowCallout"
          :title="badgePopoverTitle"
          data-testid="work-item-feedback-popover"
          triggers="focus click manual blur"
          placement="bottom"
          show-close-button
          @close-button-clicked="dismiss"
        >
          {{ badgeContent }}
          <gl-link target="_blank" :href="feedbackIssue">{{ feedbackIssueText }}</gl-link
          >.
        </gl-popover>
      </template>
    </user-callout-dismisser>
  </div>
</template>
