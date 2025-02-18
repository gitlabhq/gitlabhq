<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { produce } from 'immer';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import DeleteNoteMutation from '~/wikis/graphql/notes/delete_wiki_page_note.mutation.graphql';
import { clearDraft, getDraft } from '~/lib/utils/autosave';
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { createAlert } from '~/alert';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import wikiNoteToggleAwardEmojiMutation from '~/wikis/graphql/notes/wiki_note_toggle_award_emoji.mutation.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { getIdFromGid, getAutosaveKey } from '../utils';
import NoteHeader from './note_header.vue';
import NoteBody from './note_body.vue';
import NoteActions from './note_actions.vue';

export default {
  name: 'WikiNote',
  components: {
    TimelineEntryItem,
    GlAvatarLink,
    AwardsList,
    GlAvatar,
    NoteBody,
    NoteHeader,
    NoteActions,
  },
  inject: ['noteableType', 'currentUserData', 'queryVariables'],
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
    awards() {
      return (
        this.note.awardEmoji?.nodes.map((award) => {
          return {
            ...award,
            user: {
              ...award.user,
              id: parseInt(getIdFromGid(award.user.id), 10),
            },
          };
        }) || []
      );
    },
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
    canAwardEmoji() {
      return this.note.userPermissions?.awardEmoji;
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

    isEmojiPresentForCurrentUser(name) {
      return (
        this.awards.findIndex((emoji) => {
          return emoji.name === name && emoji.user.id === this.currentUserData.id;
        }) > -1
      );
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

    getAwardEmojiNodes(name, toggledOn) {
      // If the emoji toggled on, add the emoji
      if (toggledOn) {
        // If emoji is already present in award list, no action is needed
        if (this.isEmojiPresentForCurrentUser(name)) {
          return this.note.awardEmoji.nodes;
        }

        // else make a copy of unmutable list and return the list after adding the new emoji
        const awardEmojiNodes = [...this.note.awardEmoji.nodes];
        awardEmojiNodes.push({
          name,
          __typename: 'AwardEmoji',
          user: {
            id: convertToGraphQLId(TYPENAME_USER, this.currentUserData.id),
            name: this.currentUserData.name,
            __typename: 'UserCore',
          },
        });

        return awardEmojiNodes;
      }

      // else just filter the emoji
      return this.note.awardEmoji.nodes.filter(
        (emoji) =>
          !(
            emoji.name === name &&
            parseInt(getIdFromGid(emoji.user.id), 10) === this.currentUserData.id
          ),
      );
    },

    handleAwardEmoji(name) {
      this.$apollo
        .mutate({
          mutation: wikiNoteToggleAwardEmojiMutation,
          variables: {
            name,
            awardableId: this.note.id,
          },
          optimisticResponse: {
            awardEmojiToggle: {
              errors: [],
              toggledOn: !this.isEmojiPresentForCurrentUser(name),
            },
          },
          update: (cache, data) => {
            const query = {
              query: wikiPageQuery,
              variables: this.queryVariables,
            };

            const sourceData = cache.readQuery(query);

            const newData = produce(sourceData, (draftState) => {
              const discussion = draftState.wikiPage.discussions.nodes.find(
                (d) => d.id === this.note.discussion.id,
              );
              const note = discussion.notes.nodes.find((n) => n.id === this.note.id);

              note.awardEmoji = {
                ...note.awardEmoji,
                nodes: this.getAwardEmojiNodes(name, data.data.awardEmojiToggle.toggledOn),
              };
            });

            cache.writeQuery({ ...query, data: newData });
          },
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
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
            :can-award-emoji="canAwardEmoji"
            @reply="$emit('reply')"
            @edit="toggleEditing(true)"
            @delete="deleteNote"
            @award-emoji="handleAwardEmoji"
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

        <awards-list
          v-if="awards.length"
          :awards="awards"
          :can-award-emoji="canAwardEmoji"
          :current-user-id="currentUserData.id"
          class="gl-mt-5 gl-px-2"
          @award="handleAwardEmoji"
        />
      </div>

      <slot name="note-footer"> </slot>
    </div>
  </timeline-entry-item>
</template>
