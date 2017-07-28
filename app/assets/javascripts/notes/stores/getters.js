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
