export const notes = state => state.notes;

export const targetNoteHash = state => state.targetNoteHash;

export const notesById = (state) => {
  const notesByIdObject = {};

  state.notes.forEach((note) => {
    note.notes.forEach((n) => {
      notesByIdObject[n.id] = n;
    });
  });

  return notesByIdObject;
};
