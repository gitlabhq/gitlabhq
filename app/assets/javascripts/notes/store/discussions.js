import { defineStore } from 'pinia';
import { merge } from 'lodash';
import { isCurrentUser } from '~/lib/utils/common_utils';

function addReactiveDiscussionProps(discussion) {
  return {
    repliesExpanded: true,
    isReplying: false,
    hidden: false,
    ...discussion,
    notes: discussion.notes.map((note) => {
      return { ...note, isEditing: false, editedNote: null };
    }),
  };
}

export const useDiscussions = defineStore('discussions', {
  state() {
    return {
      discussions: [],
    };
  },
  actions: {
    // Pinia objects are fine to mutate if they have the properties defined initially
    /* eslint-disable no-param-reassign */
    setInitialDiscussions(discussions) {
      this.discussions = discussions.map(addReactiveDiscussionProps);
    },
    replaceDiscussion(oldDiscussion, newDiscussion) {
      this.discussions.splice(
        this.discussions.indexOf(oldDiscussion),
        1,
        addReactiveDiscussionProps(newDiscussion),
      );
    },
    addDiscussion(discussion) {
      this.discussions.push(addReactiveDiscussionProps(discussion));
    },
    deleteDiscussion(discussion) {
      this.discussions.splice(this.discussions.indexOf(discussion), 1);
    },
    toggleDiscussionReplies(discussion) {
      discussion.repliesExpanded = !discussion.repliesExpanded;
    },
    expandDiscussionReplies(discussion) {
      discussion.repliesExpanded = true;
    },
    startReplying(discussion) {
      this.expandDiscussionReplies(discussion);
      discussion.isReplying = true;
    },
    stopReplying(discussion) {
      discussion.isReplying = false;
    },
    addNote(note) {
      const { notes } = this.getDiscussionById(note.discussion_id);
      if (notes.some((existingNote) => existingNote.id === note.id)) return;
      notes.push(note);
    },
    updateNote(note) {
      merge(this.allNotesById[note.id], note);
    },
    updateNoteTextById(noteId, noteBody) {
      const note = this.allNotesById[noteId];
      note.note = noteBody;
    },
    editNote({ note, value }) {
      note.editedNote = value;
    },
    deleteNote(note) {
      const discussion = this.getDiscussionById(note.discussion_id);
      discussion.notes.splice(discussion.notes.indexOf(note), 1);
      if (discussion.notes.length === 0) this.deleteDiscussion(discussion);
    },
    setEditingMode(note, value) {
      note.isEditing = value;
      if (!value) note.editedNote = undefined;
    },
    requestLastNoteEditing(discussion) {
      const editableNote = discussion.notes.findLast((note) => {
        return isCurrentUser(note.author.id) && note.current_user?.can_edit;
      });
      if (!editableNote) return false;
      this.setEditingMode(editableNote, true);
      return true;
    },
    toggleAward({ note, award }) {
      const existingAwardIndex = note.award_emoji.findIndex(
        (emoji) => emoji.name === award && isCurrentUser(emoji.user.id),
      );
      if (existingAwardIndex !== -1) {
        note.award_emoji.splice(existingAwardIndex, 1);
      } else {
        note.award_emoji.push({
          name: award,
          user: {
            id: window.gon?.current_user_id,
            name: window.gon?.current_user_fullname,
            username: window.gon?.current_username,
          },
        });
      }
    },
    /* eslint-enable no-param-reassign */
  },
  getters: {
    getDiscussionById() {
      return (id) => this.discussions.find((discussion) => discussion.id === id);
    },
    allNotesById() {
      return this.discussions.reduce((acc, discussion) => {
        discussion.notes.forEach((note) => Object.assign(acc, { [note.id]: note }));
        return acc;
      }, {});
    },
  },
});
