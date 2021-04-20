<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __, sprintf, s__ } from '~/locale';
import ReviewerAvatarLink from './reviewer_avatar_link.vue';

const LOADING_STATE = 'loading';
const SUCCESS_STATE = 'success';

export default {
  i18n: {
    reRequestReview: __('Re-request review'),
  },
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
      loadingStates: {},
    };
  },
  watch: {
    users: {
      handler(users) {
        this.loadingStates = users.reduce(
          (acc, user) => ({
            ...acc,
            [user.id]: acc[user.id] || null,
          }),
          this.loadingStates,
        );
      },
      immediate: true,
    },
  },
  methods: {
    approvedByTooltipTitle(user) {
      return sprintf(s__('MergeRequest|Approved by @%{username}'), user);
    },
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    reRequestReview(userId) {
      this.loadingStates[userId] = LOADING_STATE;
      this.$emit('request-review', { userId, callback: this.requestReviewComplete });
    },

    requestReviewComplete(userId, success) {
      if (success) {
        this.loadingStates[userId] = SUCCESS_STATE;

        setTimeout(() => {
          this.loadingStates[userId] = null;
        }, 1500);
      } else {
        this.loadingStates[userId] = null;
      }
    },
  },
  LOADING_STATE,
  SUCCESS_STATE,
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
        v-if="user.approved"
        v-gl-tooltip.left
        :size="16"
        :title="approvedByTooltipTitle(user)"
        name="status-success"
        class="float-right gl-my-2 gl-ml-2 gl-text-green-500"
        data-testid="re-approved"
      />
      <gl-icon
        v-if="loadingStates[user.id] === $options.SUCCESS_STATE"
        :size="24"
        name="check"
        class="float-right gl-py-2 gl-mr-2 gl-text-green-500"
        data-testid="re-request-success"
      />
      <gl-button
        v-else-if="user.can_update_merge_request && user.reviewed"
        v-gl-tooltip.left
        :title="$options.i18n.reRequestReview"
        :aria-label="$options.i18n.reRequestReview"
        :loading="loadingStates[user.id] === $options.LOADING_STATE"
        class="float-right gl-text-gray-500!"
        size="small"
        icon="redo"
        variant="link"
        data-testid="re-request-button"
        @click="reRequestReview(user.id)"
      />
    </div>
  </div>
</template>
