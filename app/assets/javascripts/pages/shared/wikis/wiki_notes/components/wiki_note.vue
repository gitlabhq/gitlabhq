<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import DeleteNoteMutation from '~/wikis/graphql/notes/delete_wiki_page_note.mutation.graphql';
import { clearDraft, getDraft } from '~/lib/utils/autosave';
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { createAlert } from '~/alert';
import { getIdFromGid, getAutosaveKey } from '../utils';
import NoteHeader from './note_header.vue';
import NoteBody from './note_body.vue';
import NoteActions from './note_actions.vue';

export default {
  name: 'WikiNote',
  components: {
    TimelineEntryItem,
    GlAvatarLink,
    GlAvatar,
    NoteBody,
    NoteHeader,
    NoteActions,
  },
  inject: ['noteableType', 'currentUserData'],
  props: {
    note: {
      type: Object,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    replyNote: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditing: false,
      isUpdating: false,
      isDeleting: false,
    };
  },
  computed: {
    userSignedId() {
      return Boolean(this.currentUserData?.id);
    },
    userPermissions() {
      return this.note.userPermissions;
    },
    canReply() {
      return this.userPermissions?.createNote && this.userSignedId && !this.replyNote;
    },
    canEdit() {
      return this.userSignedId && this.userPermissions?.adminNote;
    },
    canReportAsAbuse() {
      const { currentUserData, userSignedId } = this;

      return userSignedId && currentUserData?.id.toString() !== this.authorId;
    },
    autosaveKey() {
      return getAutosaveKey(this.noteableType, this.noteId);
    },
    author() {
      return this.note.author;
    },
    authorId() {
      return getIdFromGid(this.author?.id);
    },
    noteId() {
      return getIdFromGid(this.note?.id);
    },
    noteAnchorId() {
      return `note_${this.noteId}`;
    },
    dynamicClasses() {
      return {
        timeLineEntryItem: {
          [`note-row-${this.noteId}`]: true,
          'gl-opacity-5 gl-pointer-events-none': this.isUpdating || this.isDeleting,
          'is-editable': this.canEdit,
          'internal-note': this.note.internal,
        },
        noteParent: {
          card: !this.replyNote,
          'gl-ml-7': this.replyNote,
          'gl-ml-8': !this.replyNote,
        },
      };
    },
  },
  mounted() {
    if (getDraft(this.autosaveKey)?.trim()) this.isEditing = true;
    this.updatedNote = { ...this.note };
  },
  methods: {
    toggleDeleting(value) {
      this.isDeleting = value;
    },
    toggleEditing(value) {
      if (!this.canEdit) return;

      this.isEditing = value;
      if (!this.isEditing) clearDraft(this.autosaveKey);
    },

    toggleUpdating(value) {
      this.isUpdating = value;
    },

    async deleteNote() {
      const msg = __('Are you sure you want to delete this comment?');
      const confirmed = await confirmAction(msg, {
        primaryBtnVariant: 'danger',
        primaryBtnText: __('Delete comment'),
      });

      if (confirmed) {
        this.toggleDeleting(true);

        try {
          await this.$apollo.mutate({
            mutation: DeleteNoteMutation,
            variables: { input: { id: this.note.id } },
          });

          this.$emit('note-deleted');
        } catch (err) {
          createAlert({
            message: __('Something went wrong while deleting your note. Please try again.'),
          });
          this.toggleDeleting(false);
        }
      }
    },
  },
};
</script>
<template>
  <timeline-entry-item
    :id="noteAnchorId"
    :class="dynamicClasses.timeLineEntryItem"
    :data-note-id="noteId"
    class="note note-wrapper note-comment"
    data-testid="noteable-note-container"
  >
    <div class="timeline-avatar gl-float-left">
      <gl-avatar-link
        :href="author.webPath"
        :data-user-id="authorId"
        :data-username="author.username"
        class="js-user-link g gl-relative"
      >
        <gl-avatar
          :src="author.avatarUrl"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />

        <slot name="avatar-badge"></slot>
      </gl-avatar-link>
    </div>
    <div class="gl-mb-5" :class="dynamicClasses.noteParent">
      <div class="note-content gl-px-3 gl-py-2">
        <div class="note-header">
          <note-header
            :author="author"
            :show-spinner="isUpdating"
            :created-at="note.createdAt"
            :note-id="noteId"
            :noteable-type="noteableType"
            :email-participant="note.externalAuthor"
          >
            <span class="gl-hidden sm:gl-inline">&middot;</span>
          </note-header>
          <note-actions
            :author-id="authorId"
            :show-edit="canEdit"
            :show-reply="canReply"
            :can-report-as-abuse="canReportAsAbuse"
            :note-url="note.url"
            @reply="$emit('reply')"
            @edit="toggleEditing(true)"
            @delete="deleteNote"
          />
        </div>

        <div class="timeline-discussion-body">
          <slot name="note-body">
            <note-body
              ref="noteBody"
              :note="note"
              :can-edit="canEdit"
              :is-editing="isEditing"
              :noteable-id="noteableId"
              @cancel:edit="toggleEditing(false)"
              @creating-note:start="toggleUpdating(true)"
              @creating-note:done="toggleUpdating(false)"
              @creating-note:success="toggleEditing(false)"
            />
          </slot>
        </div>
      </div>

      <slot name="note-footer"> </slot>
    </div>
  </timeline-entry-item>
</template>
