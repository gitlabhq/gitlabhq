<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { findAwardEmojiWidget, findDevelopmentWidget } from '~/work_items/utils';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    closingMergeRequestsCount() {
      return (
        this.issue.mergeRequestsCount ||
        findDevelopmentWidget(this.issue)?.closingMergeRequests?.count
      );
    },
    downvotes() {
      return this.issue.downvotes || findAwardEmojiWidget(this.issue)?.downvotes;
    },
    upvotes() {
      return this.issue.upvotes || findAwardEmojiWidget(this.issue)?.upvotes;
    },
  },
};
</script>

<template>
  <ul class="gl-contents gl-list-none">
    <li v-if="upvotes" class="gl-hidden sm:gl-mr-2 sm:gl-inline-block">
      <span v-gl-tooltip :title="__('Upvotes')" data-testid="issuable-upvotes">
        <gl-icon name="thumb-up" />
        {{ upvotes }}
      </span>
    </li>
    <li v-if="downvotes" class="gl-hidden sm:gl-mr-2 sm:gl-inline-block">
      <span v-gl-tooltip :title="__('Downvotes')" data-testid="issuable-downvotes">
        <gl-icon name="thumb-down" />
        {{ downvotes }}
      </span>
    </li>
    <li v-if="closingMergeRequestsCount" class="gl-hidden sm:gl-mr-2 sm:gl-inline-block">
      <span v-gl-tooltip :title="__('Related merge requests')" data-testid="merge-requests">
        <gl-icon name="merge-request" />
        {{ closingMergeRequestsCount }}
      </span>
    </li>
    <slot></slot>
  </ul>
</template>
