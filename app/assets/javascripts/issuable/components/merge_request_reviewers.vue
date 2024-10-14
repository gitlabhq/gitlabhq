<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  components: {
    UserAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    reviewers: {
      type: Array,
      required: true,
    },
    iconSize: {
      type: Number,
      required: false,
      default: 24,
    },
    imgCssClasses: {
      type: String,
      required: false,
      default: '',
    },
    maxVisible: {
      type: Number,
      required: false,
      default: 3,
    },
  },
  data() {
    return {
      maxReviewers: 99,
    };
  },
  computed: {
    reviewersToShow() {
      const numShownReviewers = this.reviewers.length - this.numHiddenReviewers;
      return this.reviewers.slice(0, numShownReviewers);
    },
    reviewersCounterTooltip() {
      return sprintf(__('%{count} more reviewers'), { count: this.numHiddenReviewers });
    },
    numHiddenReviewers() {
      if (this.reviewers.length > this.maxVisible) {
        return this.reviewers.length - this.maxVisible + 1;
      }
      return 0;
    },
    reviewerCounterLabel() {
      if (this.numHiddenReviewers > this.maxReviewers) {
        return `${this.maxReviewers}+`;
      }

      return `+${this.numHiddenReviewers}`;
    },
  },
  methods: {
    avatarUrlTitle(reviewer) {
      return sprintf(__('Review requested from %{reviewerName}'), {
        reviewerName: reviewer.name,
      });
    },
  },
};
</script>
<template>
  <div>
    <user-avatar-link
      v-for="reviewer in reviewersToShow"
      :key="reviewer.id"
      :link-href="reviewer.webPath"
      :img-alt="avatarUrlTitle(reviewer)"
      :img-css-classes="imgCssClasses"
      img-css-wrapper-classes="gl-inline-flex"
      :img-src="reviewer.avatarUrl"
      :img-size="iconSize"
      class="author-link"
      tooltip-placement="bottom"
    >
      <span data-testid="js-reviewer-tooltip">
        <span class="gl-block gl-font-bold">{{ s__('Label|Reviewer') }}</span> {{ reviewer.name }}
        <span v-if="reviewer.username">@{{ reviewer.username }}</span>
      </span>
    </user-avatar-link>
    <span
      v-if="numHiddenReviewers > 0"
      v-gl-tooltip.bottom
      :title="reviewersCounterTooltip"
      class="avatar-counter"
      data-testid="avatar-counter-content"
      >{{ reviewerCounterLabel }}</span
    >
  </div>
</template>
