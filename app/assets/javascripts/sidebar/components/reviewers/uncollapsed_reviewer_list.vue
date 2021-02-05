<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import ReviewerAvatarLink from './reviewer_avatar_link.vue';

const DEFAULT_RENDER_COUNT = 5;

export default {
  components: {
    GlButton,
    GlIcon,
    ReviewerAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
  data() {
    return {
      showLess: true,
      loading: false,
      requestedReviewSuccess: false,
    };
  },
  computed: {
    firstUser() {
      return this.users[0];
    },
    hasOneUser() {
      return this.users.length === 1;
    },
    hiddenReviewersLabel() {
      const { numberOfHiddenReviewers } = this;
      return sprintf(__('+ %{numberOfHiddenReviewers} more'), { numberOfHiddenReviewers });
    },
    renderShowMoreSection() {
      return this.users.length > DEFAULT_RENDER_COUNT;
    },
    numberOfHiddenReviewers() {
      return this.users.length - DEFAULT_RENDER_COUNT;
    },
    uncollapsedUsers() {
      const uncollapsedLength = this.showLess
        ? Math.min(this.users.length, DEFAULT_RENDER_COUNT)
        : this.users.length;
      return this.showLess ? this.users.slice(0, uncollapsedLength) : this.users;
    },
    username() {
      return `@${this.firstUser.username}`;
    },
  },
  methods: {
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    reRequestReview(userId) {
      this.loading = true;
      this.$emit('request-review', { userId, callback: this.requestReviewComplete });
    },
    requestReviewComplete(success) {
      if (success) {
        this.requestedReviewSuccess = true;

        setTimeout(() => {
          this.requestedReviewSuccess = false;
        }, 1500);
      }

      this.loading = false;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(user, index) in users"
      :key="user.id"
      :class="{ 'gl-mb-3': index !== users.length - 1 }"
      data-testid="reviewer"
    >
      <reviewer-avatar-link :user="user" :root-path="rootPath" :issuable-type="issuableType">
        <div class="gl-ml-3">@{{ user.username }}</div>
      </reviewer-avatar-link>
      <gl-icon
        v-if="requestedReviewSuccess"
        :size="24"
        name="check"
        class="float-right gl-text-green-500"
      />
      <gl-button
        v-else-if="user.can_update_merge_request && user.reviewed"
        v-gl-tooltip.left
        :title="__('Re-request review')"
        :loading="loading"
        class="float-right gl-text-gray-500!"
        size="small"
        icon="redo"
        variant="link"
        @click="reRequestReview(user.id)"
      />
    </div>
  </div>
</template>
