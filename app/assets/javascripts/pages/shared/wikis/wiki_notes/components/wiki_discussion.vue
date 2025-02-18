<script>
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import { getDraft, clearDraft } from '~/lib/utils/autosave';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import { getAutosaveKey, getIdFromGid } from '../utils';
import WikiNote from './wiki_note.vue';
import WikiDiscussionsSignedOut from './wiki_discussions_signed_out.vue';
import WikiCommentForm from './wiki_comment_form.vue';
import PlaceholderNote from './placeholder_note.vue';

export default {
  name: 'WikiDiscussion',
  components: {
    TimelineEntryItem,
    WikiNote,
    PlaceholderNote,
    WikiCommentForm,
    DiscussionReplyPlaceholder,
    WikiDiscussionsSignedOut,
    ToggleRepliesWidget,
  },
  inject: ['noteableType', 'currentUserData'],
  props: {
    discussion: {
      type: Array,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isReplying: false,
      replies: [],
      firstNote: {},
      placeholderNote: {},
      collapsed: false,
    };
  },
  computed: {
    renderPlaceHolderNote() {
      return Boolean(this.placeholderNote.body);
    },
    canReply() {
      return this.userSignedId && this.getUserPermissions(this.firstNote).createNote;
    },
    renderReplyPlaceHolder() {
      return this.canReply && !this.isReplying;
    },
    renderCommentForm() {
      return this.isReplying && this.canReply;
    },
    userSignedId() {
      return Boolean(this.currentUserData?.id);
    },
    author() {
      const { author } = this.firstNote;
      return {
        ...author,
        id: getIdFromGid(author.id),
      };
    },
    noteId() {
      return getIdFromGid(this.firstNote.id);
    },
    discussionId() {
      return getIdFromGid(this.firstNote.discussion?.id);
    },
    autosaveKey() {
      return getAutosaveKey(this.noteableType, this.discussionId);
    },
    externalAuthor() {
      return '';
    },
  },
  watch: {
    discussion: {
      immediate: true,
      handler() {
        this.populateReplies();
      },
    },
  },
  mounted() {
    if (getDraft(this.autosaveKey)?.trim()) {
      this.isReplying = true;
    }
  },
  methods: {
    populateReplies() {
      const discussionCopy = [...this.discussion];
      this.firstNote = discussionCopy.shift() || {};
      this.replies = discussionCopy;
    },
    setPlaceHolderNote(note) {
      this.placeholderNote = note;
    },
    toggleReplying(value) {
      this.isReplying = value;
      if (!this.isReplying) clearDraft(this.autosaveKey);
    },
    updateNote() {
      this.placeholderNote = {};
      this.toggleReplying(false);
    },
    getUserPermissions(note) {
      return JSON.parse(JSON.stringify(note.userPermissions || {}));
    },
    toggleCollapsed() {
      this.collapsed = !this.collapsed;
    },
  },
};
</script>
<template>
  <timeline-entry-item class="note discussion note-comment">
    <wiki-note
      :key="firstNote.id"
      :user-permissions="getUserPermissions(firstNote)"
      :note="firstNote"
      :noteable-id="noteableId"
      @reply="toggleReplying(true)"
      @note-deleted="$emit('note-deleted', firstNote.id)"
    >
      <template v-if="replies.length || isReplying" #note-footer>
        <div
          data-testid="wiki-note-footer"
          class="gl-border-t-1 gl-border-t-[#dcdcde] gl-bg-subtle gl-border-t-solid"
        >
          <toggle-replies-widget
            v-if="replies.length"
            :replies="replies"
            :collapsed="collapsed"
            @toggle="toggleCollapsed"
          />

          <div
            v-if="!collapsed"
            class="note-footer discussion-reply-holder clearfix gl-px-5 gl-py-4"
          >
            <div v-for="reply in replies" :key="reply.id">
              <wiki-note
                reply-note
                data-testid="wiki-reply-note"
                :noteable-id="noteableId"
                :user-permissions="getUserPermissions(reply)"
                :note="reply"
                @note-deleted="$emit('note-deleted', reply.id)"
              />
            </div>

            <div v-if="!!placeholderNote.body" class="notes main-notes-list timeline">
              <placeholder-note reply-note :note="placeholderNote" />
            </div>

            <wiki-discussions-signed-out v-if="!userSignedId" />
            <discussion-reply-placeholder
              v-else-if="renderReplyPlaceHolder"
              @focus="toggleReplying(true)"
            />
            <wiki-comment-form
              v-else-if="renderCommentForm"
              ref="commentForm"
              is-reply
              :noteable-id="noteableId"
              :note-id="discussionId"
              :discussion-id="firstNote.discussion.id"
              @cancel="toggleReplying(false)"
              @creating-note:start="setPlaceHolderNote"
              @creating-note:success="updateNote"
              @creating-note:done="setPlaceHolderNote({})"
            />
          </div>
        </div>
      </template>
    </wiki-note>
  </timeline-entry-item>
</template>
