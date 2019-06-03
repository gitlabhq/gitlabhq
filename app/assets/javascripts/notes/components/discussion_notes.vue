<script>
import { mapGetters } from 'vuex';
import { SYSTEM_NOTE } from '../constants';
import { __ } from '~/locale';
import NoteableNote from './noteable_note.vue';
import PlaceholderNote from '../../vue_shared/components/notes/placeholder_note.vue';
import PlaceholderSystemNote from '../../vue_shared/components/notes/placeholder_system_note.vue';
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
import ToggleRepliesWidget from './toggle_replies_widget.vue';
import NoteEditedText from './note_edited_text.vue';

export default {
  name: 'DiscussionNotes',
  components: {
    ToggleRepliesWidget,
    NoteEditedText,
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
  },
  methods: {
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
  },
};
</script>

<template>
  <div class="discussion-notes">
    <ul class="notes">
      <template v-if="shouldGroupReplies">
        <component
          :is="componentName(firstNote)"
          :note="componentData(firstNote)"
          :line="line"
          :commit="commit"
          :help-page-path="helpPagePath"
          :show-reply-button="userCanReply"
          @handle-delete-note="$emit('deleteNote')"
          @start-replying="$emit('startReplying')"
        >
          <note-edited-text
            v-if="discussion.resolved"
            slot="discussion-resolved-text"
            :edited-at="discussion.resolved_at"
            :edited-by="discussion.resolved_by"
            :action-text="resolvedText"
            class-name="discussion-headline-light js-discussion-headline discussion-resolved-text"
          />
          <slot slot="avatar-badge" name="avatar-badge"></slot>
        </component>
        <toggle-replies-widget
          v-if="hasReplies"
          :collapsed="!isExpanded"
          :replies="replies"
          @toggle="$emit('toggleDiscussion')"
        />
        <template v-if="isExpanded">
          <component
            :is="componentName(note)"
            v-for="note in replies"
            :key="note.id"
            :note="componentData(note)"
            :help-page-path="helpPagePath"
            :line="line"
            @handle-delete-note="$emit('deleteNote')"
          />
        </template>
      </template>
      <template v-else>
        <component
          :is="componentName(note)"
          v-for="(note, index) in discussion.notes"
          :key="note.id"
          :note="componentData(note)"
          :help-page-path="helpPagePath"
          :line="diffLine"
          @handle-delete-note="$emit('deleteNote')"
        >
          <slot v-if="index === 0" slot="avatar-badge" name="avatar-badge"></slot>
        </component>
      </template>
    </ul>
    <slot :show-replies="isExpanded || !hasReplies" name="footer"></slot>
  </div>
</template>
