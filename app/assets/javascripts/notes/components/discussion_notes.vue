<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions } from 'vuex';
import { __ } from '~/locale';
import PlaceholderNote from '~/vue_shared/components/notes/placeholder_note.vue';
import PlaceholderSystemNote from '~/vue_shared/components/notes/placeholder_system_note.vue';
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
import { FILE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { SYSTEM_NOTE } from '../constants';
import DiscussionNotesRepliesWrapper from './discussion_notes_replies_wrapper.vue';
import NoteEditedText from './note_edited_text.vue';
import NoteableNote from './noteable_note.vue';
import ToggleRepliesWidget from './toggle_replies_widget.vue';

export default {
  name: 'DiscussionNotes',
  components: {
    ToggleRepliesWidget,
    NoteEditedText,
    DiscussionNotesRepliesWrapper,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    isExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    diffLine: {
      type: Object,
      required: false,
      default: null,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    shouldGroupReplies: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    isOverviewTab: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['userCanReply']),
    hasReplies() {
      return Boolean(this.replies.length);
    },
    replies() {
      return this.discussion.notes.slice(1);
    },
    firstNote() {
      return this.discussion.notes.slice(0, 1)[0];
    },
    resolvedText() {
      return this.discussion.resolved_by_push ? __('Automatically resolved') : __('Resolved');
    },
    commit() {
      if (!this.discussion.for_commit) {
        return null;
      }

      return {
        id: this.discussion.commit_id,
        url: this.discussion.discussion_path,
      };
    },
    isDiscussionInternal() {
      return this.discussion.notes[0]?.internal;
    },
    isFileDiscussion() {
      return this.discussion.position?.position_type === FILE_DIFF_POSITION_TYPE;
    },
  },
  methods: {
    ...mapActions(['toggleDiscussion', 'setSelectedCommentPositionHover']),
    componentName(note) {
      if (note.isPlaceholderNote) {
        if (note.placeholderType === SYSTEM_NOTE) {
          return PlaceholderSystemNote;
        }

        return PlaceholderNote;
      }

      if (note.system) {
        return SystemNote;
      }

      return NoteableNote;
    },
    componentData(note) {
      return note.isPlaceholderNote ? note.notes[0] : note;
    },
    handleMouseEnter(discussion) {
      if (discussion.position) {
        this.setSelectedCommentPositionHover(discussion.position.line_range);
      }
    },
    handleMouseLeave(discussion) {
      // Even though position isn't used here we still don't want to unnecessarily call a mutation
      // The lack of position tells us that highlighting is irrelevant in this context
      if (discussion.position) {
        this.setSelectedCommentPositionHover();
      }
    },
  },
};
</script>

<template>
  <div class="discussion-notes">
    <ul
      class="notes"
      @mouseenter="handleMouseEnter(discussion)"
      @mouseleave="handleMouseLeave(discussion)"
    >
      <template v-if="shouldGroupReplies">
        <component
          :is="componentName(firstNote)"
          :note="componentData(firstNote)"
          :line="line || diffLine"
          :discussion-file="discussion.diff_file"
          :commit="commit"
          :help-page-path="helpPagePath"
          :show-reply-button="userCanReply"
          :discussion-root="true"
          :discussion-resolve-path="discussion.resolve_path"
          :is-overview-tab="isOverviewTab"
          :internal-note="isDiscussionInternal"
          :class="{ '!gl-border-t-0': isFileDiscussion }"
          @handleDeleteNote="$emit('deleteNote')"
          @startReplying="$emit('startReplying')"
        >
          <template #discussion-resolved-text>
            <note-edited-text
              v-if="discussion.resolved"
              :edited-at="discussion.resolved_at"
              :edited-by="discussion.resolved_by"
              :action-text="resolvedText"
              class-name="discussion-headline-light js-discussion-headline discussion-resolved-text -gl-mt-2 gl-mb-3 gl-ml-3"
            />
          </template>
          <template #avatar-badge>
            <slot name="avatar-badge"></slot>
          </template>
        </component>
        <discussion-notes-replies-wrapper
          v-if="hasReplies || userCanReply"
          :is-diff-discussion="discussion.diff_discussion"
        >
          <toggle-replies-widget
            v-if="hasReplies"
            :collapsed="!isExpanded"
            :replies="replies"
            @toggle="toggleDiscussion({ discussionId: discussion.id })"
          />
          <template v-if="isExpanded">
            <component
              :is="componentName(note)"
              v-for="note in replies"
              :key="note.id"
              :note="componentData(note)"
              :help-page-path="helpPagePath"
              :line="line"
              :internal-note="isDiscussionInternal"
              @handleDeleteNote="$emit('deleteNote')"
            />
          </template>
          <slot :show-replies="isExpanded || !hasReplies" name="footer"></slot>
        </discussion-notes-replies-wrapper>
      </template>
      <template v-else>
        <component
          :is="componentName(note)"
          v-for="(note, index) in discussion.notes"
          :key="note.id"
          :note="componentData(note)"
          :discussion-file="discussion.diff_file"
          :help-page-path="helpPagePath"
          :line="diffLine"
          :discussion-root="index === 0"
          :discussion-resolve-path="discussion.resolve_path"
          :is-overview-tab="isOverviewTab"
          :internal-note="isDiscussionInternal"
          @handleDeleteNote="$emit('deleteNote')"
        >
          <template #avatar-badge>
            <slot v-if="index === 0" name="avatar-badge"></slot>
          </template>
        </component>
        <slot :show-replies="isExpanded || !hasReplies" name="footer"></slot>
      </template>
    </ul>
  </div>
</template>
