<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, sprintf, s__ } from '~/locale';
import ReviewerAvatarLink from './reviewer_avatar_link.vue';

const LOADING_STATE = 'loading';
const SUCCESS_STATE = 'success';
const JUST_APPROVED = 'approved';

const REVIEW_STATE_ICONS = {
  APPROVED: {
    name: 'check-circle',
    iconClass: 'gl-fill-icon-success',
    title: s__('MergeRequest|Reviewer approved changes'),
  },
  REQUESTED_CHANGES: {
    name: 'error',
    iconClass: 'gl-fill-icon-danger',
    title: s__('MergeRequest|Reviewer requested changes'),
  },
  REVIEWED: {
    name: 'comment-lines',
    iconClass: 'gl-fill-icon-info',
    title: s__('MergeRequest|Reviewer commented'),
  },
  UNREVIEWED: {
    name: 'dash-circle',
    iconClass: 'gl-fill-icon-default',
    title: s__('MergeRequest|Awaiting review'),
  },
  REVIEW_STARTED: {
    name: 'comment-dots',
    iconClass: 'gl-fill-icon-default',
    title: s__('MergeRequest|Reviewer started review'),
  },
};

export default {
  i18n: {
    reRequestReview: __('Re-request review'),
    removeReviewer: s__('MergeRequest|Remove reviewer'),
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
    isEditable: {
      type: Boolean,
      required: false,
      default: false,
    },
    canRerequest: {
      type: Boolean,
      required: true,
      default: false,
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
    removeReviewer(userId) {
      this.loadingStates[userId] = LOADING_STATE;
      this.$emit('remove-reviewer', {
        userId,
        done: () => this.requestRemovalComplete(userId),
      });
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
    requestRemovalComplete(userId) {
      delete this.loadingStates[userId];
    },
    reviewStateIcon(user) {
      if (user.mergeRequestInteraction.approved) {
        return {
          ...REVIEW_STATE_ICONS.APPROVED,
          class: [this.loadingStates[user.id] === JUST_APPROVED && 'merge-request-approved-icon'],
        };
      }
      return (
        REVIEW_STATE_ICONS[user.mergeRequestInteraction.reviewState] ||
        REVIEW_STATE_ICONS.UNREVIEWED
      );
    },
    showRequestReviewButton(user) {
      if (this.canRerequest) {
        if (!user.mergeRequestInteraction.approved) {
          return !['UNREVIEWED'].includes(user.mergeRequestInteraction.reviewState);
        }

        return true;
      }

      return false;
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
      class="reviewer-grid gl-mr-2 gl-grid gl-items-center"
      data-testid="reviewer"
    >
      <reviewer-avatar-link
        :user="user"
        :root-path="rootPath"
        :issuable-type="issuableType"
        class="gl-mr-2 gl-break-anywhere"
        data-css-area="user"
      >
        <div class="gl-ml-3 gl-grid gl-items-center gl-leading-normal">
          {{ user.name }}
        </div>
      </reviewer-avatar-link>
      <gl-button
        v-if="showRequestReviewButton(user)"
        v-gl-tooltip.left
        :title="$options.i18n.reRequestReview"
        :aria-label="$options.i18n.reRequestReview"
        :loading="loadingStates[user.id] === $options.LOADING_STATE"
        class="gl-float-right gl-mr-2 !gl-text-subtle"
        size="small"
        icon="redo"
        variant="link"
        data-testid="re-request-button"
        @click="reRequestReview(user.id)"
      />
      <span
        v-gl-tooltip.top.viewport
        :title="reviewStateIcon(user).title"
        class="gl-float-right gl-my-2 gl-ml-auto gl-shrink-0"
        :class="reviewStateIcon(user).class"
        data-testid="reviewer-state-icon-parent"
      >
        <gl-icon
          :size="reviewStateIcon(user).size || 16"
          :name="reviewStateIcon(user).name"
          :class="reviewStateIcon(user).iconClass"
          :aria-label="reviewStateIcon(user).title"
          data-testid="reviewer-state-icon"
        />
      </span>
      <span v-if="isEditable" class="gl-inline-flex gl-h-6 gl-w-6">
        <gl-button
          v-gl-tooltip.top.viewport
          :title="$options.i18n.removeReviewer"
          :aria-label="$options.i18n.removeReviewer"
          :loading="loadingStates[user.id] === $options.LOADING_STATE"
          class="gl-float-right gl-ml-2 !gl-text-subtle"
          size="small"
          icon="close"
          variant="link"
          data-testid="remove-request-button"
          @click="removeReviewer(user.id)"
        />
      </span>
    </div>
  </div>
</template>
