export const notes = state => state.notes;
export const targetNoteHash = state => state.targetNoteHash;
export const getNotesDataByProp = state => prop => state.notesData[prop];
export const getIssueDataByProp = state => prop => state.notesData[prop];
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
