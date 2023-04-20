<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, sprintf, s__ } from '~/locale';
import ReviewerAvatarLink from './reviewer_avatar_link.vue';

const LOADING_STATE = 'loading';
const SUCCESS_STATE = 'success';
const JUST_APPROVED = 'approved';

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
      default: TYPE_ISSUE,
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
      handler(users, previousUsers) {
        this.loadingStates = users.reduce(
          (acc, user) => ({
            ...acc,
            [user.id]: acc[user.id] || null,
          }),
          this.loadingStates,
        );
        if (previousUsers) {
          users.forEach((user) => {
            const userPreviousState = previousUsers.find(({ id }) => id === user.id);
            if (
              userPreviousState &&
              user.mergeRequestInteraction.approved &&
              !userPreviousState.mergeRequestInteraction.approved
            ) {
              this.showApprovalAnimation(user.id);
            }
          });
        }
      },
      immediate: true,
    },
  },
  methods: {
    showApprovalAnimation(userId) {
      this.loadingStates[userId] = JUST_APPROVED;

      setTimeout(() => {
        this.loadingStates[userId] = null;
      }, 1500);
    },
    approveAnimation(userId) {
      return {
        'merge-request-approved-icon': this.loadingStates[userId] === JUST_APPROVED,
      };
    },
    approvedByTooltipTitle(user) {
      return sprintf(s__('MergeRequest|Approved by @%{username}'), user);
    },
    reviewedButNotApprovedTooltip(user) {
      return sprintf(s__('MergeRequest|Reviewed by @%{username} but not yet approved'), user);
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
      :class="{
        'gl-mb-3': index !== users.length - 1,
      }"
      class="gl-display-grid gl-align-items-center reviewer-grid gl-mr-2"
      data-testid="reviewer"
    >
      <reviewer-avatar-link
        :user="user"
        :root-path="rootPath"
        :issuable-type="issuableType"
        class="gl-word-break-word gl-mr-2"
        data-css-area="user"
      >
        <div class="gl-ml-3 gl-line-height-normal gl-display-grid gl-align-items-center">
          {{ user.name }}
        </div>
      </reviewer-avatar-link>
      <gl-button
        v-if="user.mergeRequestInteraction.canUpdate && user.mergeRequestInteraction.reviewed"
        v-gl-tooltip.left
        :title="$options.i18n.reRequestReview"
        :aria-label="$options.i18n.reRequestReview"
        :loading="loadingStates[user.id] === $options.LOADING_STATE"
        class="float-right gl-text-gray-500! gl-mr-2"
        size="small"
        icon="redo"
        variant="link"
        data-testid="re-request-button"
        @click="reRequestReview(user.id)"
      />
      <gl-icon
        v-if="user.mergeRequestInteraction.approved"
        v-gl-tooltip.left
        :size="16"
        :title="approvedByTooltipTitle(user)"
        name="status-success"
        class="float-right gl-my-2 gl-ml-auto gl-text-green-500 gl-flex-shrink-0"
        :class="approveAnimation(user.id)"
        data-testid="approved"
      />
      <gl-icon
        v-else-if="user.mergeRequestInteraction.reviewed"
        v-gl-tooltip.left
        :size="16"
        :title="reviewedButNotApprovedTooltip(user)"
        name="dotted-circle"
        class="float-right gl-my-2 gl-ml-auto gl-text-gray-400 gl-flex-shrink-0"
        data-testid="reviewed-not-approved"
      />
    </div>
  </div>
</template>
