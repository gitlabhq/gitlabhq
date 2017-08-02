export const notes = state => state.notes;
export const targetNoteHash = state => state.targetNoteHash;

export const getNotesData = state => state.notesData;
export const getNotesDataByProp = state => prop => state.notesData[prop];

export const getIssueData = state => state.issueData;
export const getIssueDataByProp = state => prop => state.issueData[prop];

export const getUserData = state => state.userData;
export const getUserDataByProp = state => prop => state.userData && state.userData[prop];

export const notesById = state => state.notes.reduce((acc, note) => {
  note.notes.every(n => Object.assign(acc, { [n.id]: n }));
  return acc;
}, {});

const reverseNotes = array => array.slice(0).reverse();
const isLastNote = (note, userId) => !note.system && note.author.id === userId;

export const getCurrentUserLastNote = state => userId => reverseNotes(state.notes)
  .reduce((acc, note) => {
    acc.push(reverseNotes(note.notes).find(el => isLastNote(el, userId)));
    return acc;
  }, []).filter(el => el !== undefined)[0];

// eslint-disable-next-line no-unused-vars
export const getDiscussionLastNote = state => (discussion, userId) => reverseNotes(discussion.notes)
  .find(el => isLastNote(el, userId));

