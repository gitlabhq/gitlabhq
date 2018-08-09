import _ from 'underscore';
import * as constants from '../constants';
import { collapseSystemNotes } from './collapse_utils';

export const discussions = state => collapseSystemNotes(state.discussions);

export const targetNoteHash = state => state.targetNoteHash;

export const getNotesData = state => state.notesData;

export const isNotesFetched = state => state.isNotesFetched;

export const getNotesDataByProp = state => prop => state.notesData[prop];

export const getNoteableData = state => state.noteableData;

export const getNoteableDataByProp = state => prop => state.noteableData[prop];

export const openState = state => state.noteableData.state;

export const getUserData = state => state.userData || {};

export const getUserDataByProp = state => prop => state.userData && state.userData[prop];

export const notesById = state =>
  state.discussions.reduce((acc, note) => {
    note.notes.every(n => Object.assign(acc, { [n.id]: n }));
    return acc;
  }, {});

export const discussionsByLineCode = state =>
  state.discussions.reduce((acc, note) => {
    if (note.diff_discussion && note.line_code && note.resolvable) {
      // For context about line notes: there might be multiple notes with the same line code
      const items = acc[note.line_code] || [];
      items.push(note);

      Object.assign(acc, { [note.line_code]: items });
    }
    return acc;
  }, {});

export const noteableType = state => {
  const { ISSUE_NOTEABLE_TYPE, MERGE_REQUEST_NOTEABLE_TYPE, EPIC_NOTEABLE_TYPE } = constants;

  if (state.noteableData.noteableType === EPIC_NOTEABLE_TYPE) {
    return EPIC_NOTEABLE_TYPE;
  }

  return state.noteableData.merge_params ? MERGE_REQUEST_NOTEABLE_TYPE : ISSUE_NOTEABLE_TYPE;
};

const reverseNotes = array => array.slice(0).reverse();

const isLastNote = (note, state) =>
  !note.system && state.userData && note.author && note.author.id === state.userData.id;

export const getCurrentUserLastNote = state =>
  _.flatten(reverseNotes(state.discussions).map(note => reverseNotes(note.notes))).find(el =>
    isLastNote(el, state),
  );

export const getDiscussionLastNote = state => discussion =>
  reverseNotes(discussion.notes).find(el => isLastNote(el, state));

export const discussionCount = state => {
  const filteredDiscussions = state.discussions.filter(n => !n.individual_note && n.resolvable);

  return filteredDiscussions.length;
};

export const unresolvedDiscussions = (state, getters) => {
  const resolvedMap = getters.resolvedDiscussionsById;

  return state.discussions.filter(n => !n.individual_note && !resolvedMap[n.id]);
};

export const allDiscussions = (state, getters) => {
  const resolved = getters.resolvedDiscussionsById;
  const unresolved = getters.unresolvedDiscussions;

  return Object.values(resolved).concat(unresolved);
};

export const allResolvableDiscussions = (state, getters) =>
  getters.allDiscussions.filter(d => !d.individual_note && d.resolvable);

export const resolvedDiscussionsById = state => {
  const map = {};

  state.discussions.filter(d => d.resolvable).forEach(n => {
    if (n.notes) {
      const resolved = n.notes.filter(note => note.resolvable).every(note => note.resolved);

      if (resolved) {
        map[n.id] = n;
      }
    }
  });

  return map;
};

// Gets Discussions IDs ordered by the date of their initial note
export const unresolvedDiscussionsIdsByDate = (state, getters) =>
  getters.allResolvableDiscussions
    .filter(d => !d.resolved)
    .sort((a, b) => {
      const aDate = new Date(a.notes[0].created_at);
      const bDate = new Date(b.notes[0].created_at);

      if (aDate < bDate) {
        return -1;
      }

      return aDate === bDate ? 0 : 1;
    })
    .map(d => d.id);

// Gets Discussions IDs ordered by their position in the diff
//
// Sorts the array of resolvable yet unresolved discussions by
// comparing file names first. If file names are the same, compares
// line numbers.
export const unresolvedDiscussionsIdsByDiff = (state, getters) =>
  getters.allResolvableDiscussions
    .filter(d => !d.resolved)
    .sort((a, b) => {
      if (!a.diff_file || !b.diff_file) {
        return 0;
      }

      // Get file names comparison result
      const filenameComparison = a.diff_file.file_path.localeCompare(b.diff_file.file_path);

      // Get the line numbers, to compare within the same file
      const aLines = [a.position.formatter.new_line, a.position.formatter.old_line];
      const bLines = [b.position.formatter.new_line, b.position.formatter.old_line];

      return filenameComparison < 0 ||
        (filenameComparison === 0 &&
          // .max() because one of them might be zero (if removed/added)
          Math.max(aLines[0], aLines[1]) < Math.max(bLines[0], bLines[1]))
        ? -1
        : 1;
    })
    .map(d => d.id);

export const resolvedDiscussionCount = (state, getters) => {
  const resolvedMap = getters.resolvedDiscussionsById;

  return Object.keys(resolvedMap).length;
};

export const discussionTabCounter = state => {
  let all = [];

  state.discussions.forEach(discussion => {
    all = all.concat(discussion.notes.filter(note => !note.system && !note.placeholder));
  });

  return all.length;
};

// Returns the list of discussion IDs ordered according to given parameter
// @param {Boolean} diffOrder - is ordered by diff?
export const unresolvedDiscussionsIdsOrdered = (state, getters) => diffOrder => {
  if (diffOrder) {
    return getters.unresolvedDiscussionsIdsByDiff;
  }
  return getters.unresolvedDiscussionsIdsByDate;
};

// Checks if a given discussion is the last in the current order (diff or date)
// @param {Boolean} discussionId - id of the discussion
// @param {Boolean} diffOrder - is ordered by diff?
export const isLastUnresolvedDiscussion = (state, getters) => (discussionId, diffOrder) => {
  const idsOrdered = getters.unresolvedDiscussionsIdsOrdered(diffOrder);
  const lastDiscussionId = idsOrdered[idsOrdered.length - 1];

  return lastDiscussionId === discussionId;
};

// Gets the ID of the discussion following the one provided, respecting order (diff or date)
// @param {Boolean} discussionId - id of the current discussion
// @param {Boolean} diffOrder - is ordered by diff?
export const nextUnresolvedDiscussionId = (state, getters) => (discussionId, diffOrder) => {
  const idsOrdered = getters.unresolvedDiscussionsIdsOrdered(diffOrder);
  const currentIndex = idsOrdered.indexOf(discussionId);

  return idsOrdered.slice(currentIndex + 1, currentIndex + 2)[0];
};

// @param {Boolean} diffOrder - is ordered by diff?
export const firstUnresolvedDiscussionId = (state, getters) => diffOrder => {
  if (diffOrder) {
    return getters.unresolvedDiscussionsIdsByDiff[0];
  }
  return getters.unresolvedDiscussionsIdsByDate[0];
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
