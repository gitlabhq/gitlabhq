<script>
import { mapGetters } from 'vuex';
import { GlTooltipDirective, GlIcon, GlButton, GlDropdownItem } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import resolvedStatusMixin from '~/batch_comments/mixins/resolved_status';
import ReplyButton from './note_actions/reply_button.vue';
import eventHub from '~/sidebar/event_hub';
import Api from '~/api';
import { deprecatedCreateFlash as flash } from '~/flash';
import { splitCamelCase } from '../../lib/utils/text_utility';

export default {
  name: 'NoteActions',
  components: {
    GlIcon,
    ReplyButton,
    GlButton,
    GlDropdownItem,
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
        this.$root.$emit('bv::hide::tooltip');
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
        assignees = assignees.filter(assignee => assignee.id !== this.author.id);
      } else {
        assignees.push({ id: this.author.id });
      }

      if (this.targetType === 'issue') {
        Api.updateIssue(project_id, iid, {
          assignee_ids: assignees.map(assignee => assignee.id),
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
    <span
      v-if="isAuthor"
      class="note-role user-access-role has-tooltip d-none d-md-inline-block"
      :title="displayAuthorBadgeText"
      >{{ __('Author') }}</span
    >
    <span
      v-if="accessLevel"
      class="note-role user-access-role has-tooltip"
      :title="displayMemberBadgeText"
      >{{ accessLevel }}</span
    >
    <span
      v-else-if="isContributor"
      class="note-role user-access-role has-tooltip"
      :title="displayContributorBadgeText"
      >{{ __('Contributor') }}</span
    >
    <div v-if="canResolve" class="gl-ml-2">
      <gl-button
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
    </div>
    <div v-if="canAwardEmoji" class="gl-ml-3 gl-mr-2">
      <a
        v-gl-tooltip
        :class="{ 'js-user-authored': isAuthoredByCurrentUser }"
        class="note-action-button note-emoji-button js-add-award js-note-emoji"
        href="#"
        title="Add reaction"
        data-position="right"
      >
        <gl-icon class="link-highlight award-control-icon-neutral" name="slight-smile" />
        <gl-icon class="link-highlight award-control-icon-positive" name="smiley" />
        <gl-icon class="link-highlight award-control-icon-super-positive" name="smile" />
      </a>
    </div>
    <reply-button
      v-if="showReply"
      ref="replyButton"
      class="js-reply-button"
      @startReplying="$emit('startReplying')"
    />
    <div v-if="canEdit" class="gl-ml-2">
      <gl-button
        v-gl-tooltip
        title="Edit comment"
        icon="pencil"
        size="small"
        category="tertiary"
        class="note-action-button js-note-edit btn btn-transparent"
        data-qa-selector="note_edit_button"
        @click="onEdit"
      />
    </div>
    <div v-if="showDeleteAction" class="gl-ml-2">
      <gl-button
        v-gl-tooltip
        title="Delete comment"
        size="small"
        icon="remove"
        category="tertiary"
        class="note-action-button js-note-delete btn btn-transparent"
        @click="onDelete"
      />
    </div>
    <div v-else-if="shouldShowActionsDropdown" class="dropdown more-actions gl-ml-2">
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
