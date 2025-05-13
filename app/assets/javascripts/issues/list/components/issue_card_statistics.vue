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
        findDevelopmentWidget(this.issue)?.closingMergeRequests.count
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
  <ul class="gl-contents">
    <li
      v-if="upvotes"
      v-gl-tooltip
      class="gl-hidden sm:gl-block"
      :title="__('Upvotes')"
      data-testid="issuable-upvotes"
    >
      <gl-icon name="thumb-up" />
      {{ upvotes }}
    </li>
    <li
      v-if="downvotes"
      v-gl-tooltip
      class="gl-hidden sm:gl-block"
      :title="__('Downvotes')"
      data-testid="issuable-downvotes"
    >
      <gl-icon name="thumb-down" />
      {{ downvotes }}
    </li>
    <li
      v-if="closingMergeRequestsCount"
      v-gl-tooltip
      class="gl-hidden sm:gl-block"
      :title="__('Related merge requests')"
      data-testid="merge-requests"
    >
      <gl-icon name="merge-request" />
      {{ closingMergeRequestsCount }}
    </li>
    <slot></slot>
  </ul>
</template>
