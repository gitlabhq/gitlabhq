<script>
import {
  GlButton,
  GlIcon,
  GlTooltipDirective,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { __, s__ } from '~/locale';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import addAwardEmojiMutation from '../../graphql/notes/work_item_note_add_award_emoji.mutation.graphql';

export default {
  name: 'WorkItemNoteActions',
  i18n: {
    editButtonText: __('Edit comment'),
    moreActionsText: __('More actions'),
    deleteNoteText: __('Delete comment'),
    copyLinkText: __('Copy link'),
    assignUserText: __('Assign to commenting user'),
    unassignUserText: __('Unassign from commenting user'),
    reportAbuseText: __('Report abuse to administrator'),
  },
  components: {
    GlButton,
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    ReplyButton,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
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
  },
  computed: {
    assignUserActionText() {
      return this.isAuthorAnAssignee
        ? this.$options.i18n.unassignUserText
        : this.$options.i18n.assignUserText;
    },
  },

  methods: {
    async setAwardEmoji(name) {
      try {
        const {
          data: {
            awardEmojiAdd: { errors = [] },
          },
        } = await this.$apollo.mutate({
          mutation: addAwardEmojiMutation,
          variables: {
            awardableId: this.noteId,
            name,
          },
        });

        if (errors.length > 0) {
          throw new Error(errors[0].message);
        }
      } catch (error) {
        this.$emit('error', s__('WorkItem|Failed to award emoji'));
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
    <emoji-picker
      v-if="showAwardEmoji && glFeatures.workItemsMvc2"
      toggle-class="note-action-button note-emoji-button btn-icon btn-default-tertiary"
      data-testid="note-emoji-button"
      @click="setAwardEmoji"
    >
      <template #button-content>
        <gl-icon class="award-control-icon-neutral gl-button-icon gl-icon" name="slight-smile" />
        <gl-icon
          class="award-control-icon-positive gl-button-icon gl-icon gl-left-3!"
          name="smiley"
        />
        <gl-icon
          class="award-control-icon-super-positive gl-button-icon gl-icon gl-left-3!"
          name="smile"
        />
      </template>
    </emoji-picker>
    <reply-button v-if="showReply" ref="replyButton" @startReplying="$emit('startReplying')" />
    <gl-button
      v-if="showEdit"
      v-gl-tooltip
      data-testid="edit-work-item-note"
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
      data-testid="work-item-note-actions"
      icon="ellipsis_v"
      text-sr-only
      placement="right"
      :toggle-text="$options.i18n.moreActionsText"
      :title="$options.i18n.moreActionsText"
      category="tertiary"
      no-caret
    >
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
        data-testid="copy-link-action"
        :data-clipboard-text="noteUrl"
        @action="emitEvent('notifyCopyDone')"
      >
        <template #list-item>
          {{ $options.i18n.copyLinkText , }}
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
      <gl-disclosure-dropdown-item
        v-if="showEdit"
        data-testid="delete-note-action"
        @action="emitEvent('deleteNote')"
      >
        <template #list-item>
          <span class="gl-text-red-500">{{ $options.i18n.deleteNoteText }}</span>
        </template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </div>
</template>
