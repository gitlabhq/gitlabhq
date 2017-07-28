export const notes = state => state.notes;
export const targetNoteHash = state => state.targetNoteHash;

export const getNotesData = state => state.notesData;
export const getNotesDataByProp = state => prop => state.notesData[prop];

export const getIssueData = state => state.issueData;
export const getIssueDataByProp = state => prop => state.issueData[prop];

export const getUserData = state => state.userData;
export const getUserDataByProp = state => prop => state.notesData[prop];

export const notesById = (state) => {
  const notesByIdObject = {};
  // TODO: FILIPA: TRANSFORM INTO A REDUCE
  state.notes.forEach((note) => {
    note.notes.forEach((n) => {
      notesByIdObject[n.id] = n;
    });
  });

  return notesByIdObject;
};

const reverseNotes = array => array.slice(0).reverse();
const isLastNote = (note, userId) => !note.system && note.author.id === userId;

export const getCurrentUserLastNote = state => userId => reverseNotes(state.notes)
  .reduce((acc, note) => {
    acc.push(reverseNotes(note.notes).find(el => isLastNote(el, userId)));
    return acc;
  }, []).filter(el => el !== undefined)[0];

export const getDiscussionLastNote = state => (discussion, userId) => reverseNotes(discussion[0].notes)
  .find(el => isLastNote(el, userId));

