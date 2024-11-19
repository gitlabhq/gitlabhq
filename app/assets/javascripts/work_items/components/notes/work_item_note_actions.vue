<script>
import {
  GlButton,
  GlTooltipDirective,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __, sprintf } from '~/locale';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import { getMutation, optimisticAwardUpdate } from '../../notes/award_utils';

export default {
  name: 'WorkItemNoteActions',
  i18n: {
    editButtonText: __('Edit comment'),
    moreActionsText: __('More actions'),
    deleteNoteText: __('Delete comment'),
    copyLinkText: __('Copy link'),
    assignUserText: __('Assign to commenting user'),
    unassignUserText: __('Unassign from commenting user'),
    reportAbuseText: __('Report abuse'),
    resolveThreadTitle: __('Resolve thread'),
  },
  components: {
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    ReplyButton,
    UserAccessRoleBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    note: {
      type: Object,
      required: true,
    },
    showReply: {
      type: Boolean,
      required: true,
    },
    showEdit: {
      type: Boolean,
      required: true,
    },
    noteId: {
      type: String,
      required: true,
    },
    showAwardEmoji: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteUrl: {
      type: String,
      required: false,
      default: '',
    },
    isAuthorAnAssignee: {
      type: Boolean,
      required: false,
      default: false,
    },
    showAssignUnassign: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReportAbuse: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemType: {
      type: String,
      required: true,
    },
    isWorkItemAuthor: {
      type: Boolean,
      required: false,
      default: false,
    },
    isAuthorContributor: {
      type: Boolean,
      required: false,
      default: false,
    },
    maxAccessLevelOfAuthor: {
      type: String,
      required: false,
      default: '',
    },
    projectName: {
      type: String,
      required: false,
      default: '',
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
  },
  computed: {
    assignUserActionText() {
      return this.isAuthorAnAssignee
        ? this.$options.i18n.unassignUserText
        : this.$options.i18n.assignUserText;
    },
    displayAuthorBadgeText() {
      return sprintf(__('This user is the author of this %{workItemType}.'), {
        workItemType: this.workItemType.toLowerCase(),
      });
    },
    displayMemberBadgeText() {
      return sprintf(__('This user has the %{access} role in the %{name} project.'), {
        access: this.maxAccessLevelOfAuthor.toLowerCase(),
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
    resolveThreadTitle() {
      return this.isResolved
        ? __('Resolved by ') + this.resolvedBy.name
        : this.$options.i18n.resolveThreadTitle;
    },
  },
  methods: {
    async setAwardEmoji(name) {
      const { mutation, mutationName, errorMessage } = getMutation({ note: this.note, name });

      try {
        await this.$apollo.mutate({
          mutation,
          variables: {
            awardableId: this.note.id,
            name,
          },
          optimisticResponse: {
            [mutationName]: {
              errors: [],
            },
          },
          update: optimisticAwardUpdate({
            note: this.note,
            name,
            fullPath: this.fullPath,
            workItemIid: this.workItemIid,
          }),
        });
      } catch (error) {
        this.$emit('error', errorMessage);
        Sentry.captureException(error);
      }
    },
    emitEvent(eventName) {
      this.$emit(eventName);
      this.$refs.dropdown.close();
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <user-access-role-badge
      v-if="isWorkItemAuthor"
      v-gl-tooltip
      :title="displayAuthorBadgeText"
      class="gl-mr-3 gl-hidden sm:gl-block"
      data-testid="author-badge"
    >
      {{ __('Author') }}
    </user-access-role-badge>
    <user-access-role-badge
      v-if="maxAccessLevelOfAuthor"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden sm:gl-block"
      :title="displayMemberBadgeText"
      data-testid="max-access-level-badge"
    >
      {{ maxAccessLevelOfAuthor }}
    </user-access-role-badge>
    <user-access-role-badge
      v-else-if="isAuthorContributor"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden sm:gl-block"
      :title="displayContributorBadgeText"
      data-testid="contributor-badge"
    >
      {{ __('Contributor') }}
    </user-access-role-badge>
    <gl-button
      v-if="canResolve"
      ref="resolveButton"
      v-gl-tooltip.hover
      data-testid="resolve-line-button"
      category="tertiary"
      class="note-action-button"
      :class="{ '!gl-text-success': isResolved }"
      :title="resolveThreadTitle"
      :aria-label="resolveThreadTitle"
      :icon="resolveIcon"
      :loading="isResolving"
      @click="$emit('resolve')"
    />
    <emoji-picker
      v-if="showAwardEmoji"
      toggle-class="add-reaction-button btn-default-tertiary"
      data-testid="note-emoji-button"
      @click="setAwardEmoji"
    />
    <reply-button v-if="showReply" ref="replyButton" @startReplying="$emit('startReplying')" />
    <gl-button
      v-if="showEdit"
      v-gl-tooltip
      data-testid="note-actions-edit"
      data-track-action="click_button"
      data-track-label="edit_button"
      category="tertiary"
      icon="pencil"
      :title="$options.i18n.editButtonText"
      :aria-label="$options.i18n.editButtonText"
      @click="$emit('startEditing')"
    />
    <gl-disclosure-dropdown
      ref="dropdown"
      v-gl-tooltip
      icon="ellipsis_v"
      text-sr-only
      placement="bottom-end"
      :toggle-text="$options.i18n.moreActionsText"
      :title="$options.i18n.moreActionsText"
      category="tertiary"
      no-caret
    >
      <gl-disclosure-dropdown-item
        data-testid="copy-link-action"
        :data-clipboard-text="noteUrl"
        @action="emitEvent('notifyCopyDone')"
      >
        <template #list-item>
          {{ $options.i18n.copyLinkText }}
        </template>
      </gl-disclosure-dropdown-item>
      <gl-disclosure-dropdown-item
        v-if="showAssignUnassign"
        data-testid="assign-note-action"
        @action="emitEvent('assignUser')"
      >
        <template #list-item>
          {{ assignUserActionText }}
        </template>
      </gl-disclosure-dropdown-item>
      <gl-disclosure-dropdown-group v-if="canReportAbuse || showEdit" bordered>
        <gl-disclosure-dropdown-item
          v-if="canReportAbuse"
          data-testid="abuse-note-action"
          @action="emitEvent('reportAbuse')"
        >
          <template #list-item>
            {{ $options.i18n.reportAbuseText }}
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="showEdit"
          data-testid="delete-note-action"
          @action="emitEvent('deleteNote')"
        >
          <template #list-item>
            <span class="gl-text-red-500">{{ $options.i18n.deleteNoteText }}</span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
  </div>
</template>
