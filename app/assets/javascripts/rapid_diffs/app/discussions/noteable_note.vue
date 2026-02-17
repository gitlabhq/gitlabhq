<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { createAlert } from '~/alert';
import { HTTP_STATUS_GONE } from '~/lib/utils/http_status';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { __, sprintf } from '~/locale';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { isCurrentUser } from '~/lib/utils/common_utils';
import { UPDATE_COMMENT_FORM } from '~/notes/i18n';
import NoteActions from './note_actions.vue';
import NoteBody from './note_body.vue';
import NoteHeader from './note_header.vue';
import TimelineEntryItem from './timeline_entry_item.vue';

export default {
  name: 'NoteableNote',
  UPDATE_COMMENT_FORM,
  components: {
    NoteHeader,
    NoteActions,
    NoteBody,
    GlAvatarLink,
    GlAvatar,
    TimelineEntryItem,
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
    timelineLayout: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLastDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDeleting: false,
      isSaving: false,
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
    async saveNote(noteText) {
      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });

      if (!confirmSubmit) return;

      this.isSaving = true;

      try {
        const {
          data: { note: updatedNote },
        } = await axios.put(this.note.path, {
          rapid_diffs: true,
          target_id: this.note.noteable_id,
          note: { note: noteText },
        });
        this.$emit('cancelEditing');
        this.$emit('noteUpdated', updatedNote);
      } catch (error) {
        if (error.response && error.response.status === HTTP_STATUS_GONE) {
          this.$emit('noteDeleted');
        } else {
          throw error;
        }
      } finally {
        this.isSaving = false;
      }
    },
    onCancelEditing: ignoreWhilePending(async function cancel(shouldConfirm) {
      if (shouldConfirm) {
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
    :timeline-layout="timelineLayout"
    :is-last-discussion="isLastDiscussion"
    :class="{
      'gl-pointer-events-none gl-opacity-5': isSaving || isDeleting,
      'gl-bg-[var(--note-background)]': !timelineLayout,
    }"
    class="[--note-background:initial] target:[--note-background:var(--timeline-entry-target-background-color)]"
    data-testid="noteable-note-container"
  >
    <!-- Avatar slot for timeline layout -->
    <template #avatar>
      <gl-avatar-link
        :href="author.path"
        :data-user-id="authorId"
        :data-username="author.username"
        class="js-user-link gl-mt-2"
      >
        <gl-avatar
          :src="author.avatar_url"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />
      </gl-avatar-link>
    </template>

    <!-- Content slot for timeline layout, default slot for non-timeline -->
    <template #content>
      <div
        :class="{
          'gl-border gl-rounded-lg gl-border-section gl-bg-[var(--note-background)]':
            timelineLayout,
        }"
      >
        <div
          class="gl-flex gl-flex-wrap gl-items-start gl-justify-between gl-gap-2 gl-px-4 gl-pt-2"
        >
          <note-header
            class="gl-my-1 gl-py-2"
            :author="author"
            :created-at="note.created_at"
            :note-id="note.id"
            :is-internal-note="note.internal"
            :is-imported="note.imported"
            :show-avatar="!timelineLayout"
          >
            <template #avatar-badge>
              <slot name="avatar-badge"></slot>
            </template>
          </note-header>
          <note-actions
            :author-id="authorId"
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
        <div class="gl-pb-4 gl-pr-4" :class="timelineLayout ? 'gl-pl-4' : 'gl-ml-2 gl-pl-8'">
          <note-body
            :note="note"
            :can-edit="canEdit"
            :is-editing="isEditing"
            :autosave-key="autosaveKey"
            :restore-from-autosave="restoreFromAutosave"
            :save-note="saveNote"
            :save-note-error-messages="$options.UPDATE_COMMENT_FORM"
            @cancelEditing="onCancelEditing"
            @input="$emit('noteEdited', $event)"
            @award="toggleAward"
          />
        </div>
        <slot name="footer"></slot>
      </div>
    </template>
  </timeline-entry-item>
</template>
