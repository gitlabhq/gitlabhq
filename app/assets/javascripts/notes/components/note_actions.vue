<script>
import { GlTooltipDirective, GlIcon, GlButton, GlDropdownItem } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import Api from '~/api';
import resolvedStatusMixin from '~/batch_comments/mixins/resolved_status';
import createFlash from '~/flash';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { splitCamelCase } from '../../lib/utils/text_utility';
import ReplyButton from './note_actions/reply_button.vue';

export default {
  i18n: {
    addReactionLabel: __('Add reaction'),
    editCommentLabel: __('Edit comment'),
    deleteCommentLabel: __('Delete comment'),
    moreActionsLabel: __('More actions'),
  },
  name: 'NoteActions',
  components: {
    GlIcon,
    ReplyButton,
    GlButton,
    GlDropdownItem,
    UserAccessRoleBadge,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
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
    // This can be undefined when `canAwardEmoji` is false
    awardPath: {
      type: String,
      required: false,
      default: '',
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
    ...mapActions(['toggleAwardRequest']),
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
          .catch(() =>
            createFlash({
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
    <template v-if="canAwardEmoji">
      <emoji-picker
        v-if="glFeatures.improvedEmojiPicker"
        toggle-class="note-action-button note-emoji-button gl-text-gray-600 gl-m-3 gl-p-0! gl-shadow-none! gl-bg-transparent!"
        @click="setAwardEmoji"
      >
        <template #button-content>
          <gl-icon class="link-highlight award-control-icon-neutral gl-m-0!" name="slight-smile" />
          <gl-icon class="link-highlight award-control-icon-positive gl-m-0!" name="smiley" />
          <gl-icon class="link-highlight award-control-icon-super-positive gl-m-0!" name="smile" />
        </template>
      </emoji-picker>
      <gl-button
        v-else
        v-gl-tooltip
        :class="{ 'js-user-authored': isAuthoredByCurrentUser }"
        class="note-action-button note-emoji-button add-reaction-button js-add-award js-note-emoji"
        category="tertiary"
        variant="default"
        :title="$options.i18n.addReactionLabel"
        :aria-label="$options.i18n.addReactionLabel"
        data-position="right"
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
    </template>
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
      data-qa-selector="note_edit_button"
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
    <div v-else-if="shouldShowActionsDropdown" class="dropdown more-actions">
      <!-- eslint-disable @gitlab/vue-no-data-toggle -->
      <gl-button
        v-gl-tooltip
        :title="$options.i18n.moreActionsLabel"
        :aria-label="$options.i18n.moreActionsLabel"
        icon="ellipsis_v"
        category="tertiary"
        class="note-action-button more-actions-toggle"
        data-toggle="dropdown"
        @click="closeTooltip"
      />
      <!-- eslint-enable @gitlab/vue-no-data-toggle -->
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
