<script>
import { GlBadge, GlPopover, GlLink } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { ROUTES } from '../../work_items/constants';

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
  computed: {
    shouldUseDismissal() {
      return Boolean(this.featureName);
    },
    shouldShowBadge() {
      return this.$route?.name === ROUTES.index || this.$route?.name === ROUTES.savedView;
    },
  },
};
</script>

<template>
  <div
    v-if="shouldShowBadge"
    class="gl-content-center @sm/panel:gl-flex"
    data-testid="work-item-feedback"
  >
    <gl-badge :id="$options.badgeId" variant="info" icon="comment" href="#">{{
      badgeTitle
    }}</gl-badge>
    <user-callout-dismisser v-if="shouldUseDismissal" :feature-name="featureName">
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
    <gl-popover
      v-else
      :target="$options.badgeId"
      :title="badgePopoverTitle"
      :css-classes="['gl-min-w-[300px]']"
      data-testid="work-item-feedback-popover"
      triggers="focus click manual blur"
      placement="bottom"
      show-close-button
    >
      {{ badgeContent }}
      <gl-link target="_blank" :href="feedbackIssue">{{ feedbackIssueText }}</gl-link
      >.
    </gl-popover>
  </div>
</template>
