<script>
import {
  GlTooltipDirective,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import Api from '~/api';
import resolvedStatusMixin from '~/batch_comments/mixins/resolved_status';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { splitCamelCase } from '~/lib/utils/text_utility';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import ReplyButton from './note_actions/reply_button.vue';
import TimelineEventButton from './note_actions/timeline_event_button.vue';

export default {
  i18n: {
    editCommentLabel: __('Edit comment'),
    deleteCommentLabel: __('Delete comment'),
    moreActionsLabel: __('More actions'),
    reportAbuse: __('Report abuse'),
  },
  name: 'NoteActions',
  components: {
    AbuseCategorySelector,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    ReplyButton,
    TimelineEventButton,
    UserAccessRoleBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [resolvedStatusMixin, glFeatureFlagsMixin()],
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
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
    canDelete: {
      type: Boolean,
      required: true,
    },
    canResolve: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    };
  },
  computed: {
    ...mapState(['isPromoteCommentToTimelineEventInProgress']),
    ...mapGetters(['getUserDataByProp', 'getNoteableData', 'canUserAddIncidentTimelineEvents']),
    shouldShowActionsDropdown() {
      return this.currentUserId;
    },
    showDeleteAction() {
      return this.canDelete && !this.canReportAsAbuse && !this.noteUrl;
    },
    isAuthoredByCurrentUser() {
      return this.authorId === this.currentUserId;
    },
    currentUserId() {
      return this.getUserDataByProp('id');
    },
    isUserAssigned() {
      return this.assignees && this.assignees.some(({ id }) => id === this.author.id);
    },
    displayAssignUserText() {
      return this.isUserAssigned
        ? __('Unassign from commenting user')
        : __('Assign to commenting user');
    },
    sidebarAction() {
      return this.isUserAssigned ? 'sidebar.addAssignee' : 'sidebar.removeAssignee';
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
    resolveVariant() {
      return this.isResolved ? 'success' : 'default';
    },
  },
  methods: {
    ...mapActions(['toggleAwardRequest', 'promoteCommentToTimelineEvent']),
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
    onCopyUrl() {
      this.$toast.show(__('Link copied to clipboard.'));
    },
    handleAssigneeUpdate(assignees) {
      this.$emit('updateAssignees', assignees);
      eventHub.$emit(this.sidebarAction, this.author);
      eventHub.$emit('sidebar.saveAssignees');
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
      class="gl-mr-3 gl-display-none gl-sm-display-block"
      :title="displayAuthorBadgeText"
    >
      {{ __('Author') }}
    </user-access-role-badge>
    <user-access-role-badge
      v-if="accessLevel"
      v-gl-tooltip
      class="gl-mr-3 gl-display-none gl-sm-display-block"
      :title="displayMemberBadgeText"
    >
      {{ accessLevel }}
    </user-access-role-badge>
    <user-access-role-badge
      v-else-if="isContributor"
      v-gl-tooltip
      class="gl-mr-3 gl-display-none gl-sm-display-block"
      :title="displayContributorBadgeText"
    >
      {{ __('Contributor') }}
    </user-access-role-badge>
    <span class="note-actions__mobile-spacer"></span>
    <gl-button
      v-if="canResolve"
      ref="resolveButton"
      v-gl-tooltip
      category="tertiary"
      :variant="resolveVariant"
      :class="{ 'is-disabled': !resolvable, 'is-active': isResolved }"
      :title="resolveButtonTitle"
      :aria-label="resolveButtonTitle"
      :icon="resolveIcon"
      :loading="isResolving"
      class="line-resolve-btn note-action-button"
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
      class="note-action-button js-note-edit gl-display-none gl-sm-display-block"
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
        placement="right"
        class="note-action-button more-actions-toggle"
        no-caret
      >
        <gl-disclosure-dropdown-item
          v-if="canEdit"
          class="js-note-edit gl-sm-display-none!"
          @action="onEdit"
        >
          <template #list-item>
            {{ __('Edit comment') }}
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="canReportAsAbuse"
          data-testid="report-abuse-button"
          @action="onAbuse"
        >
          <template #list-item>
            {{ $options.i18n.reportAbuse }}
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="noteUrl"
          class="js-btn-copy-note-link"
          :data-clipboard-text="noteUrl"
          @action="onCopyUrl"
        >
          <template #list-item>
            {{ __('Copy link') }}
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="canAssign"
          data-testid="assign-user"
          @action="assignUser"
        >
          <template #list-item>
            {{ displayAssignUserText }}
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item v-if="canEdit" class="js-note-delete" @action="onDelete">
          <template #list-item>
            <span class="text-danger">{{ __('Delete comment') }}</span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>
    </div>
    <!-- IMPORTANT: show this component lazily because it causes layout thrashing -->
    <!-- https://gitlab.com/gitlab-org/gitlab/-/issues/331172#note_1269378396 -->
    <abuse-category-selector
      v-if="canReportAsAbuse && isReportAbuseDrawerOpen"
      :reported-user-id="authorId"
      :reported-from-url="noteUrl"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="toggleReportAbuseDrawer(false)"
    />
  </div>
</template>
