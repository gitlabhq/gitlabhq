<script>
import { GlTooltipDirective, GlIcon, GlButton, GlDropdownItem } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import Api from '~/api';
import resolvedStatusMixin from '~/batch_comments/mixins/resolved_status';
import { deprecatedCreateFlash as flash } from '~/flash';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { splitCamelCase } from '../../lib/utils/text_utility';
import ReplyButton from './note_actions/reply_button.vue';

export default {
  name: 'NoteActions',
  components: {
    GlIcon,
    ReplyButton,
    GlButton,
    GlDropdownItem,
    UserAccessRoleBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [resolvedStatusMixin],
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
    reportAbusePath: {
      type: String,
      required: false,
      default: null,
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
  },
  computed: {
    ...mapGetters(['getUserDataByProp', 'getNoteableData']),
    shouldShowActionsDropdown() {
      return this.currentUserId && (this.canEdit || this.canReportAsAbuse);
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
      return this.targetType === 'issue';
    },
    canAssign() {
      return this.getNoteableData.current_user?.can_update && this.isIssue;
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
    onEdit() {
      this.$emit('handleEdit');
    },
    onDelete() {
      this.$emit('handleDelete');
    },
    onResolve() {
      this.$emit('handleResolve');
    },
    closeTooltip() {
      this.$nextTick(() => {
        this.$root.$emit(BV_HIDE_TOOLTIP);
      });
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

      if (this.targetType === 'issue') {
        Api.updateIssue(project_id, iid, {
          assignee_ids: assignees.map((assignee) => assignee.id),
        })
          .then(() => this.handleAssigneeUpdate(assignees))
          .catch(() => flash(__('Something went wrong while updating assignees')));
      }
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <user-access-role-badge
      v-if="isAuthor"
      v-gl-tooltip
      class="gl-mx-3 d-none d-md-inline-block"
      :title="displayAuthorBadgeText"
    >
      {{ __('Author') }}
    </user-access-role-badge>
    <user-access-role-badge
      v-if="accessLevel"
      v-gl-tooltip
      class="gl-mx-3"
      :title="displayMemberBadgeText"
    >
      {{ accessLevel }}
    </user-access-role-badge>
    <user-access-role-badge
      v-else-if="isContributor"
      v-gl-tooltip
      class="gl-mx-3"
      :title="displayContributorBadgeText"
    >
      {{ __('Contributor') }}
    </user-access-role-badge>
    <gl-button
      v-if="canResolve"
      ref="resolveButton"
      v-gl-tooltip
      size="small"
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
    <gl-button
      v-if="canAwardEmoji"
      v-gl-tooltip
      :class="{ 'js-user-authored': isAuthoredByCurrentUser }"
      class="note-action-button note-emoji-button add-reaction-button js-add-award js-note-emoji"
      category="tertiary"
      variant="default"
      size="small"
      title="Add reaction"
      data-position="right"
      :aria-label="__('Add reaction')"
    >
      <span class="reaction-control-icon reaction-control-icon-neutral">
        <gl-icon name="slight-smile" />
      </span>
      <span class="reaction-control-icon reaction-control-icon-positive">
        <gl-icon name="smiley" />
      </span>
      <span class="reaction-control-icon reaction-control-icon-super-positive">
        <gl-icon name="smile" />
      </span>
    </gl-button>
    <reply-button
      v-if="showReply"
      ref="replyButton"
      class="js-reply-button"
      @startReplying="$emit('startReplying')"
    />
    <gl-button
      v-if="canEdit"
      v-gl-tooltip
      title="Edit comment"
      icon="pencil"
      size="small"
      category="tertiary"
      class="note-action-button js-note-edit btn btn-transparent"
      data-qa-selector="note_edit_button"
      @click="onEdit"
    />
    <gl-button
      v-if="showDeleteAction"
      v-gl-tooltip
      title="Delete comment"
      size="small"
      icon="remove"
      category="tertiary"
      class="note-action-button js-note-delete btn btn-transparent"
      @click="onDelete"
    />
    <div v-else-if="shouldShowActionsDropdown" class="dropdown more-actions">
      <gl-button
        v-gl-tooltip
        title="More actions"
        icon="ellipsis_v"
        size="small"
        category="tertiary"
        class="note-action-button more-actions-toggle btn btn-transparent"
        data-toggle="dropdown"
        @click="closeTooltip"
      />
      <ul class="dropdown-menu more-actions-dropdown dropdown-open-left">
        <gl-dropdown-item v-if="canReportAsAbuse" :href="reportAbusePath">
          {{ __('Report abuse to admin') }}
        </gl-dropdown-item>
        <gl-dropdown-item
          v-if="noteUrl"
          class="js-btn-copy-note-link"
          :data-clipboard-text="noteUrl"
        >
          {{ __('Copy link') }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="canAssign" data-testid="assign-user" @click="assignUser">
          {{ displayAssignUserText }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="canEdit" class="js-note-delete" @click.prevent="onDelete">
          <span class="text-danger">{{ __('Delete comment') }}</span>
        </gl-dropdown-item>
      </ul>
    </div>
  </div>
</template>
