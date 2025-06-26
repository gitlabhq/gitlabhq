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
  <li class="!gl-mr-0 gl-contents">
    <ul class="gl-contents gl-list-none">
      <li v-if="upvotes">
        <span
          v-gl-tooltip
          class="gl-hidden sm:gl-block"
          :title="__('Upvotes')"
          data-testid="issuable-upvotes"
        >
          <gl-icon name="thumb-up" />
          {{ upvotes }}
        </span>
      </li>
      <li v-if="downvotes">
        <span
          v-gl-tooltip
          class="gl-hidden sm:gl-block"
          :title="__('Downvotes')"
          data-testid="issuable-downvotes"
        >
          <gl-icon name="thumb-down" />
          {{ downvotes }}
        </span>
      </li>
      <li v-if="closingMergeRequestsCount">
        <span
          v-gl-tooltip
          class="gl-hidden sm:gl-block"
          :title="__('Related merge requests')"
          data-testid="merge-requests"
        >
          <gl-icon name="merge-request" />
          {{ closingMergeRequestsCount }}
        </span>
      </li>
      <slot></slot>
    </ul>
  </li>
</template>
