<script>
import {
  GlTooltipDirective,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import Api from '~/api';
import resolvedStatusMixin from '~/batch_comments/mixins/resolved_status';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, sprintf, s__ } from '~/locale';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { splitCamelCase } from '~/lib/utils/text_utility';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import { useNotes } from '~/notes/store/legacy_notes';
import Tracking from '~/tracking';
import ReplyButton from './note_actions/reply_button.vue';
import TimelineEventButton from './note_actions/timeline_event_button.vue';

export default {
  i18n: {
    editCommentLabel: __('Edit comment'),
    deleteCommentLabel: __('Delete comment'),
    moreActionsLabel: __('More actions'),
    reportAbuse: __('Report abuse'),
    GENIE_CHAT_FEEDBACK_THANKS: s__('AI|Thanks for your feedback!'),
  },
  name: 'NoteActions',
  components: {
    AbuseCategorySelector,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    ReplyButton,
    TimelineEventButton,
    UserAccessRoleBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [resolvedStatusMixin, Tracking.mixin()],
  props: {
    author: {
      type: Object,
      required: true,
    },
    authorId: {
      type: Number,
      required: true,
    },
    noteId: {
      type: [String, Number],
      required: true,
    },
    noteUrl: {
      type: String,
      required: false,
      default: '',
    },
    accessLevel: {
      type: String,
      required: false,
      default: '',
    },
    isAmazonQCodeReview: {
      type: Boolean,
      required: false,
      default: false,
    },
    isAuthor: {
      type: Boolean,
      required: false,
      default: false,
    },
    isContributor: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteableType: {
      type: String,
      required: false,
      default: '',
    },
    projectName: {
      type: String,
      required: false,
      default: '',
    },
    showReply: {
      type: Boolean,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    canAwardEmoji: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    canResolve: {
      type: Boolean,
      required: false,
      default: false,
    },
    // eslint-disable-next-line vue/no-unused-properties -- resolvable is part of the component's public API.
    resolvable: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
    // eslint-disable-next-line vue/no-unused-properties -- resolvedBy is part of the component's public API.
    resolvedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    canReportAsAbuse: {
      type: Boolean,
      required: true,
    },
    // This can be undefined when `canAwardEmoji` is false
    awardPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isReportAbuseDrawerOpen: false,
      feedbackReceived: false,
    };
  },
  computed: {
    ...mapState(useNotes, [
      'isPromoteCommentToTimelineEventInProgress',
      'getUserDataByProp',
      'getNoteableData',
      'canUserAddIncidentTimelineEvents',
    ]),
    shouldShowActionsDropdown() {
      return this.currentUserId;
    },
    showDeleteAction() {
      return this.canDelete && !this.canReportAsAbuse && !this.noteUrl;
    },
    currentUserId() {
      return this.getUserDataByProp('id');
    },
    isUserAssigned() {
      return this.assignees && this.assignees.some(({ id }) => id === this.author.id);
    },
    displayAssignUserText() {
      return this.isUserAssigned ? __('Unassign comment author') : __('Assign to comment author');
    },
    targetType() {
      return this.getNoteableData.targetType;
    },
    noteableDisplayName() {
      return splitCamelCase(this.noteableType).toLowerCase();
    },
    assignees() {
      return this.getNoteableData.assignees || [];
    },
    isIssue() {
      return this.targetType === TYPE_ISSUE;
    },
    canAssign() {
      return this.getNoteableData.current_user?.can_set_issue_metadata && this.isIssue;
    },
    displayAuthorBadgeText() {
      return sprintf(__('This user is the author of this %{noteable}.'), {
        noteable: this.noteableDisplayName,
      });
    },
    displayMemberBadgeText() {
      return sprintf(__('This user has the %{access} role in the %{name} project.'), {
        access: this.accessLevel.toLowerCase(),
        name: this.projectName,
      });
    },
    displayContributorBadgeText() {
      return sprintf(__('This user has previously committed to the %{name} project.'), {
        name: this.projectName,
      });
    },
    resolveIcon() {
      if (!this.isResolving) {
        return this.isResolved ? 'check-circle-filled' : 'check-circle';
      }
      return null;
    },
    feedbackModalComponent() {
      // Only load the EE component if this is an Amazon Q code review
      if (this.isAmazonQCodeReview) {
        return () => import('ee_component/ai/components/duo_chat_feedback_modal.vue');
      }
      return null;
    },
  },
  methods: {
    ...mapActions(useNotes, ['toggleAwardRequest', 'promoteCommentToTimelineEvent']),
    onEdit() {
      this.$emit('handleEdit');
    },
    onDelete() {
      this.$emit('handleDelete');
    },
    onResolve() {
      this.$emit('handleResolve');
    },
    onAbuse() {
      this.toggleReportAbuseDrawer(true);
    },
    showFeedbackModal() {
      this.$refs.feedbackModal.show();
    },
    /**
     * Tracks feedback submitted for Amazon Q code reviews
     * @param {Object} options - The feedback options
     * @param {Array<string>} [options.feedbackOptions] - Array of selected feedback options (e.g. ['helpful', 'incorrect'])
     * @param {string} [options.extendedFeedback] - Additional text feedback provided by the user
     */
    trackFeedback({ feedbackOptions, extendedFeedback } = {}) {
      this.track('amazon_q_code_review_feedback', {
        action: 'amazon_q',
        label: 'code_review_feedback',
        property: feedbackOptions,
        extra: {
          extendedFeedback,
          note_id: this.noteId,
        },
      });

      this.feedbackReceived = true;
    },
    onCopyUrl() {
      this.$toast.show(__('Link copied to clipboard.'));
    },
    handleAssigneeUpdate(assignees) {
      this.$emit('updateAssignees', assignees);
    },
    assignUser() {
      let { assignees } = this;
      const { project_id, iid } = this.getNoteableData;

      if (this.isUserAssigned) {
        assignees = assignees.filter((assignee) => assignee.id !== this.author.id);
      } else {
        assignees.push({ id: this.author.id });
      }

      if (this.targetType === TYPE_ISSUE) {
        Api.updateIssue(project_id, iid, {
          assignee_ids: assignees.map((assignee) => assignee.id),
        })
          .then(() => this.handleAssigneeUpdate(assignees))
          .catch(() =>
            createAlert({
              message: __('Something went wrong while updating assignees'),
            }),
          );
      }
    },
    setAwardEmoji(awardName) {
      this.toggleAwardRequest({
        endpoint: this.awardPath,
        noteId: this.noteId,
        awardName,
      });
    },
    toggleReportAbuseDrawer(isOpen) {
      this.isReportAbuseDrawerOpen = isOpen;
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <user-access-role-badge
      v-if="isAuthor"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="displayAuthorBadgeText"
    >
      {{ __('Author') }}
    </user-access-role-badge>
    <user-access-role-badge
      v-if="accessLevel"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="displayMemberBadgeText"
    >
      {{ accessLevel }}
    </user-access-role-badge>
    <user-access-role-badge
      v-else-if="isContributor"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="displayContributorBadgeText"
    >
      {{ __('Contributor') }}
    </user-access-role-badge>
    <span class="note-actions__mobile-spacer"></span>
    <gl-button
      v-if="canResolve"
      ref="resolveButton"
      v-gl-tooltip
      data-testid="resolve-line-button"
      category="tertiary"
      class="note-action-button"
      :class="{ '!gl-text-success': isResolved }"
      :title="resolveButtonTitle"
      :aria-label="resolveButtonTitle"
      :icon="resolveIcon"
      :loading="isResolving"
      @click="onResolve"
    />
    <timeline-event-button
      v-if="canUserAddIncidentTimelineEvents"
      :note-id="noteId"
      :is-promotion-in-progress="isPromoteCommentToTimelineEventInProgress"
      @click-promote-comment-to-event="promoteCommentToTimelineEvent"
    />
    <emoji-picker
      v-if="canAwardEmoji"
      toggle-class="add-reaction-button btn-default-tertiary"
      data-testid="note-emoji-button"
      @click="setAwardEmoji"
    />
    <reply-button
      v-if="showReply"
      ref="replyButton"
      class="js-reply-button"
      @startReplying="$emit('startReplying')"
    />
    <gl-button
      v-if="canEdit"
      v-gl-tooltip
      :title="$options.i18n.editCommentLabel"
      :aria-label="$options.i18n.editCommentLabel"
      icon="pencil"
      category="tertiary"
      class="note-action-button js-note-edit"
      data-testid="note-edit-button"
      @click="onEdit"
    />
    <gl-button
      v-if="showDeleteAction"
      v-gl-tooltip
      :title="$options.i18n.deleteCommentLabel"
      :aria-label="$options.i18n.deleteCommentLabel"
      icon="remove"
      category="tertiary"
      class="note-action-button js-note-delete"
      @click="onDelete"
    />
    <div v-else-if="shouldShowActionsDropdown" class="more-actions dropdown">
      <gl-disclosure-dropdown
        v-gl-tooltip
        :title="$options.i18n.moreActionsLabel"
        :toggle-text="$options.i18n.moreActionsLabel"
        text-sr-only
        icon="ellipsis_v"
        category="tertiary"
        placement="bottom-end"
        class="note-action-button more-actions-toggle"
        no-caret
      >
        <gl-disclosure-dropdown-item
          v-if="noteUrl"
          class="js-btn-copy-note-link"
          :data-clipboard-text="noteUrl"
          @action="onCopyUrl"
        >
          <template #list-item> {{ __('Copy link') }} </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="canAssign"
          data-testid="assign-user"
          @action="assignUser"
        >
          <template #list-item> {{ displayAssignUserText }} </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-group v-if="canReportAsAbuse || canEdit" bordered>
          <gl-disclosure-dropdown-item
            v-if="canReportAsAbuse"
            data-testid="report-abuse-button"
            @action="onAbuse"
          >
            <template #list-item> {{ $options.i18n.reportAbuse }} </template>
          </gl-disclosure-dropdown-item>
          <gl-disclosure-dropdown-item
            v-if="isAmazonQCodeReview && !feedbackReceived"
            data-testid="amazon-q-feedback-button"
            @action="showFeedbackModal"
          >
            <template #list-item> {{ s__('AmazonQ|Provide feedback on code review') }} </template>
          </gl-disclosure-dropdown-item>
          <gl-disclosure-dropdown-item
            v-if="canEdit"
            class="js-note-delete"
            variant="danger"
            @action="onDelete"
          >
            <template #list-item> {{ __('Delete comment') }} </template>
          </gl-disclosure-dropdown-item>
        </gl-disclosure-dropdown-group>
      </gl-disclosure-dropdown>
    </div>
    <!-- IMPORTANT: show this component lazily because it causes layout thrashing -->
    <!-- https://gitlab.com/gitlab-org/gitlab/-/issues/331172#note_1269378396 -->
    <component
      :is="feedbackModalComponent"
      v-if="feedbackModalComponent && !feedbackReceived"
      ref="feedbackModal"
      @feedback-submitted="trackFeedback"
    />
    <abuse-category-selector
      v-if="canReportAsAbuse && isReportAbuseDrawerOpen"
      :reported-user-id="authorId"
      :reported-from-url="noteUrl"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="toggleReportAbuseDrawer(false)"
    />
  </div>
</template>
