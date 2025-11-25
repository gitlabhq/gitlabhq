import { defineStore } from 'pinia';
import { merge } from 'lodash';
import { isCurrentUser } from '~/lib/utils/common_utils';

function addReactiveDiscussionProps(discussion) {
  return Object.assign(discussion, {
    repliesExpanded: true,
    isReplying: false,
    notes: discussion.notes.map((note) => {
      return Object.assign(note, { isEditing: false, editedNote: null });
    }),
  });
}

export const useDiffDiscussions = defineStore('diffDiscussions', {
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
    editNote({ note, value }) {
      note.editedNote = value;
    },
    deleteNote(note) {
      const { notes } = this.getDiscussionById(note.discussion_id);
      notes.splice(notes.indexOf(note), 1);
    },
    setEditingMode(note, value) {
      note.isEditing = value;
    },
    requestLastNoteEditing(discussion) {
      const editableNote = discussion.notes.findLast((note) => {
        return isCurrentUser(note.author.id) && note.current_user?.can_edit;
      });
      if (!editableNote) return false;
      this.setEditingMode(editableNote, true);
      return true;
    },
    addNewLineDiscussionForm({ oldPath, newPath, oldLine, newLine }) {
      const [existingDiscussion] = this.findDiscussionsForPosition({
        oldPath,
        newPath,
        oldLine,
        newLine,
      });
      if (existingDiscussion) {
        this.startReplying(existingDiscussion);
        return existingDiscussion.id;
      }
      const id = [oldPath, newPath, oldLine, newLine].join('-');
      if (this.discussions.some((discussion) => discussion.id === id)) return id;
      this.discussions.push({
        id,
        diff_discussion: true,
        position: {
          old_path: oldPath,
          new_path: newPath,
          old_line: oldLine,
          new_line: newLine,
        },
        isForm: true,
        noteBody: '',
        shouldFocus: true,
      });
      return undefined;
    },
    removeNewLineDiscussionForm(discussion) {
      this.discussions.splice(this.discussions.indexOf(discussion), 1);
    },
    setNewLineDiscussionFormText(discussion, text) {
      discussion.noteBody = text;
    },
    setNewLineDiscussionFormAutofocus(discussion, value) {
      discussion.shouldFocus = value;
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
    findDiscussionsForPosition() {
      return ({ oldPath, newPath, oldLine, newLine }) => {
        return this.discussions.filter((discussion) => {
          return (
            !discussion.isForm &&
            discussion.diff_discussion &&
            discussion.position.old_path === oldPath &&
            discussion.position.new_path === newPath &&
            discussion.position.old_line === oldLine &&
            discussion.position.new_line === newLine
          );
        });
      };
    },
  },
});
