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
    buttonResetClasses() {
      return '!gl-cursor-default gl-border-none gl-bg-transparent gl-p-0 focus-visible:gl-focus-inset';
    },
  },
};
</script>

<template>
  <ul class="gl-contents gl-list-none">
    <li v-if="upvotes" class="gl-hidden @sm/panel:gl-mr-2 @sm/panel:gl-inline-block">
      <button
        v-gl-tooltip
        :title="__('Upvotes')"
        data-testid="issuable-upvotes"
        :class="buttonResetClasses"
      >
        <gl-icon name="thumb-up" />
        {{ upvotes }}
      </button>
    </li>
    <li v-if="downvotes" class="gl-hidden @sm/panel:gl-mr-2 @sm/panel:gl-inline-block">
      <button
        v-gl-tooltip
        :title="__('Downvotes')"
        data-testid="issuable-downvotes"
        :class="buttonResetClasses"
      >
        <gl-icon name="thumb-down" />
        {{ downvotes }}
      </button>
    </li>
    <li
      v-if="closingMergeRequestsCount"
      class="gl-hidden @sm/panel:gl-mr-2 @sm/panel:gl-inline-block"
    >
      <button
        v-gl-tooltip
        :title="__('Related merge requests')"
        data-testid="merge-requests"
        :class="buttonResetClasses"
      >
        <gl-icon name="merge-request" />
        {{ closingMergeRequestsCount }}
      </button>
    </li>
    <slot></slot>
  </ul>
</template>
