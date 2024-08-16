<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { findAwardEmojiWidget } from '~/work_items/utils';
import { i18n } from '../constants';

export default {
  i18n,
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
      :title="$options.i18n.upvotes"
      data-testid="issuable-upvotes"
    >
      <gl-icon name="thumb-up" />
      {{ upvotes }}
    </li>
    <li
      v-if="downvotes"
      v-gl-tooltip
      class="gl-hidden sm:gl-block"
      :title="$options.i18n.downvotes"
      data-testid="issuable-downvotes"
    >
      <gl-icon name="thumb-down" />
      {{ downvotes }}
    </li>
    <li
      v-if="issue.mergeRequestsCount"
      v-gl-tooltip
      class="gl-hidden sm:gl-block"
      :title="__('Related merge requests')"
      data-testid="merge-requests"
    >
      <gl-icon name="merge-request" />
      {{ issue.mergeRequestsCount }}
    </li>
    <slot></slot>
  </ul>
</template>
