import { NOTE, RED } from './constants';
import { selectById, selectNote } from './utils';

const note = `
  <p id=${NOTE} class='gitlab-message'></p>
`;

const clearNote = inputId => {
  const currentNote = selectNote();
  currentNote.innerText = '';
  currentNote.style.color = '';

  if (inputId) {
    const field = document.getElementById(inputId);
    field.style.borderColor = '';
  }
};

const postError = (message, inputId) => {
  const currentNote = selectNote();
  const field = selectById(inputId);
  field.style.borderColor = RED;
  currentNote.style.color = RED;
  currentNote.innerText = message;
};

export { clearNote, note, postError };
