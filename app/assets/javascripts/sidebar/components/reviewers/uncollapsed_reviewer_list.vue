<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlIcon,
  GlAnimatedLoaderIcon,
} from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import duoCodeReviewDepthMixin from 'ee_else_ce/sidebar/mixins/duo_code_review_depth';
import { userTypes } from '../assignees/constants';
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
  name: 'UncollapsedReviewerList',
  i18n: {
    reRequestReview: __('Re-request review'),
    removeReviewer: s__('MergeRequest|Remove reviewer'),
  },
  components: {
    GlButton,
    GlDisclosureDropdown,
    GlIcon,
    GlAnimatedLoaderIcon,
    ReviewerAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [duoCodeReviewDepthMixin],
  props: {
    users: {
      type: Array,
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
    },
  },
  emits: ['remove-reviewer', 'request-review'],
  data() {
    return {
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
    reRequestReview(userId, depth) {
      this.loadingStates[userId] = LOADING_STATE;
      this.$root.$emit(BV_HIDE_TOOLTIP);
      this.$emit('request-review', { userId, depth, callback: this.requestReviewComplete });
    },
    duoCodeReviewDepthItems(userId) {
      return [
        {
          text: s__('DuoCodeReview|Standard'),
          description: s__('DuoCodeReview|Efficient review, limited context'),
          action: () => this.reRequestReview(userId, 'STANDARD'),
        },
        {
          text: s__('DuoCodeReview|Deep'),
          description: s__('DuoCodeReview|Extensive analysis, more context'),
          action: () => this.reRequestReview(userId, 'DEEP'),
        },
      ];
    },
    removeReviewer(userId) {
      this.loadingStates[userId] = LOADING_STATE;
      this.$emit('remove-reviewer', {
        userId,
        done: () => this.requestRemovalComplete(userId),
      });
    },
    requestReviewComplete(userId, success, errorMessage) {
      if (success) {
        this.loadingStates[userId] = SUCCESS_STATE;

        setTimeout(() => {
          this.loadingStates[userId] = null;
        }, 1500);
      } else {
        this.loadingStates[userId] = null;

        if (errorMessage) {
          createAlert({ message: errorMessage });
        }
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
    isDuoCodeReviewInProgress(user) {
      return (
        user.type === userTypes.duo_code_review_bot &&
        user.mergeRequestInteraction.reviewState === 'REVIEW_STARTED'
      );
    },
    showDuoCodeReviewDepthChoice(user) {
      return (
        this.duoCodeReviewDepthChoiceEnabled &&
        user.type === userTypes.duo_code_review_bot &&
        this.showRequestReviewButton(user)
      );
    },
    showRequestReviewButton(user) {
      if (this.canRerequest) {
        if (!user.mergeRequestInteraction.approved) {
          if (this.isDuoCodeReviewInProgress(user)) {
            return false;
          }

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
        :issuable-type="issuableType"
        class="gl-mr-2 gl-break-anywhere"
        data-css-area="user"
      >
        <div class="gl-ml-3 gl-grid gl-items-center gl-leading-normal">
          {{ user.name }}
        </div>
      </reviewer-avatar-link>
      <gl-disclosure-dropdown
        v-if="showDuoCodeReviewDepthChoice(user)"
        v-gl-tooltip.left
        :title="$options.i18n.reRequestReview"
        :toggle-text="$options.i18n.reRequestReview"
        :items="duoCodeReviewDepthItems(user.id)"
        :loading="loadingStates[user.id] === $options.LOADING_STATE"
        class="gl-float-right gl-mr-2"
        toggle-class="!gl-text-subtle"
        size="small"
        icon="redo"
        category="tertiary"
        text-sr-only
        data-testid="re-request-depth-dropdown"
      >
        <template #header>
          <div
            class="gl-border-b-1 gl-border-b-dropdown-divider gl-p-3 gl-text-sm gl-font-bold gl-text-strong gl-border-b-solid"
          >
            {{ s__('DuoCodeReview|Review depth') }}
          </div>
        </template>
        <template #list-item="{ item }">
          <span class="gl-block gl-font-bold">{{ item.text }}</span>
          <span class="gl-block gl-text-sm gl-text-subtle">{{ item.description }}</span>
        </template>
      </gl-disclosure-dropdown>
      <gl-button
        v-else-if="showRequestReviewButton(user)"
        v-gl-tooltip.left
        :title="$options.i18n.reRequestReview"
        :aria-label="$options.i18n.reRequestReview"
        :loading="loadingStates[user.id] === $options.LOADING_STATE"
        class="gl-float-right gl-mr-2 !gl-text-subtle"
        size="small"
        icon="redo"
        category="tertiary"
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
        <gl-animated-loader-icon v-if="isDuoCodeReviewInProgress(user)" is-on />
        <gl-icon
          v-else
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
          category="tertiary"
          data-testid="remove-request-button"
          @click="removeReviewer(user.id)"
        />
      </span>
    </div>
  </div>
</template>
