<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { createAlert } from '~/alert';
import { HTTP_STATUS_GONE } from '~/lib/utils/http_status';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { __, sprintf } from '~/locale';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { updateNoteErrorMessage } from '~/notes/utils';
import { isCurrentUser } from '~/lib/utils/common_utils';
import NoteActions from '~/notes/components/note_actions.vue';
import NoteHeader from './note_header.vue';
import NoteBody from './note_body.vue';

export default {
  name: 'NoteableNote',
  components: {
    NoteHeader,
    NoteActions,
    NoteBody,
    TimelineEntryItem,
    GlAvatarLink,
    GlAvatar,
  },
  inject: {
    endpoints: {
      type: Object,
    },
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    showReplyButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
    restoreFromAutosave: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDeleting: false,
      isRequesting: false,
    };
  },
  computed: {
    isEditing() {
      return this.note.isEditing;
    },
    author() {
      return this.note.author;
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    commentType() {
      return this.note.internal ? __('internal note') : __('comment');
    },
    classNameBindings() {
      return {
        [`note-row-${this.note.id}`]: true,
        'is-editing': this.isEditing && !this.isRequesting,
        'is-requesting being-posted': this.isRequesting,
        'disabled-content': this.isDeleting,
        'is-editable': this.canEdit,
      };
    },
    canAwardEmoji() {
      return this.note.current_user?.can_award_emoji ?? false;
    },
    canEdit() {
      return this.note.current_user?.can_edit ?? false;
    },
    canReportAsAbuse() {
      return Boolean(this.endpoints.reportAbuse) && !isCurrentUser(this.authorId);
    },
  },
  watch: {
    isEditing: {
      handler(isEditing) {
        if (isEditing) this.$nextTick(() => this.$el.scrollIntoView());
      },
      immediate: true,
    },
  },
  methods: {
    async onDelete() {
      const msg = sprintf(__('Are you sure you want to delete this %{commentType}?'), {
        commentType: this.commentType,
      });
      const confirmed = await confirmAction(msg, {
        primaryBtnVariant: 'danger',
        primaryBtnText: this.note.internal ? __('Delete internal note') : __('Delete comment'),
      });

      if (!confirmed) return;

      this.isDeleting = true;

      try {
        await axios.delete(this.note.path);
        this.$emit('noteDeleted');
      } catch (error) {
        createAlert({
          message: __('Something went wrong while deleting your note. Please try again.'),
        });
      } finally {
        this.isDeleting = false;
      }
    },
    async saveNote({ noteText }) {
      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });

      if (!confirmSubmit) return;

      this.isRequesting = true;

      try {
        const {
          data: { note: updatedNote },
        } = await axios.put(this.note.path, {
          params: {
            target_id: this.note.noteable_id,
            note: { note: noteText },
          },
        });
        this.$emit('cancelEditing');
        this.$emit('noteUpdated', updatedNote);
      } catch (error) {
        if (error.response && error.response.status === HTTP_STATUS_GONE) {
          this.$emit('noteDeleted');
        } else {
          createAlert({
            message: updateNoteErrorMessage(error),
            error,
            parent: this.$el,
          });
        }
      } finally {
        this.isRequesting = false;
      }
    },
    onCancelEditing: ignoreWhilePending(async function cancel({ shouldConfirm, isDirty }) {
      if (shouldConfirm && isDirty) {
        const msg = sprintf(__('Are you sure you want to cancel editing this %{commentType}?'), {
          commentType: this.commentType,
        });
        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Cancel editing'),
          primaryBtnVariant: 'danger',
          secondaryBtnVariant: 'default',
          secondaryBtnText: __('Continue editing'),
          hideCancel: true,
        });
        if (!confirmed) return;
      }
      this.$emit('cancelEditing');
    }),
    async toggleAward(name) {
      try {
        await axios.post(this.note.toggle_award_path, { name });
        this.$emit('toggleAward', name);
      } catch (error) {
        createAlert({
          message: __('Failed to set a reaction. Please try again.'),
          error,
        });
      }
    },
  },
};
</script>

<template>
  <timeline-entry-item
    :id="`note_${note.id}`"
    :class="{ ...classNameBindings, 'internal-note': note.internal }"
    class="note note-wrapper note-comment"
    data-testid="noteable-note-container"
  >
    <div class="timeline-avatar gl-float-left gl-pt-2">
      <gl-avatar-link
        :href="author.path"
        :data-user-id="authorId"
        :data-username="author.username"
        class="js-user-link"
      >
        <gl-avatar
          :src="author.avatar_url"
          :entity-name="author.username"
          :alt="author.name"
          :size="24"
        />
        <slot name="avatar-badge"></slot>
      </gl-avatar-link>
    </div>
    <div class="timeline-content">
      <div class="note-header">
        <note-header
          :author="author"
          :created-at="note.created_at"
          :note-id="note.id"
          :is-internal-note="note.internal"
          :is-imported="note.imported"
        />
        <note-actions
          :author="author"
          :author-id="authorId"
          :note-id="note.id"
          :note-url="note.noteable_note_url"
          :access-level="note.human_access"
          :is-contributor="note.is_contributor"
          :is-author="note.is_noteable_author"
          :project-name="note.project_name"
          :noteable-type="note.noteable_type"
          :show-reply="showReplyButton"
          :can-edit="canEdit"
          :can-award-emoji="canAwardEmoji"
          :can-delete="canEdit"
          :can-report-as-abuse="canReportAsAbuse"
          @delete="onDelete"
          @startEditing="$emit('startEditing')"
          @startReplying="$emit('startReplying')"
          @award="toggleAward"
        />
      </div>
      <div class="timeline-discussion-body">
        <note-body
          :note="note"
          :can-edit="canEdit"
          :is-editing="isEditing"
          :autosave-key="autosaveKey"
          :restore-from-autosave="restoreFromAutosave"
          :save-note="saveNote"
          @cancelEditing="onCancelEditing"
          @input="$emit('noteEdited', $event)"
          @award="toggleAward"
        />
      </div>
    </div>
  </timeline-entry-item>
</template>
