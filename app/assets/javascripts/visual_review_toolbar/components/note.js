import { NOTE, NOTE_CONTAINER, RED } from './constants';
import { selectById, selectNote, selectNoteContainer } from './utils';

const note = `
  <div id="${NOTE_CONTAINER}" style="visibility: hidden;">
    <p id="${NOTE}" class="gitlab-message"></p>
  </div>
`;

const clearNote = inputId => {
  const currentNote = selectNote();
  const noteContainer = selectNoteContainer();

  currentNote.innerText = '';
  currentNote.style.color = '';
  noteContainer.style.visibility = 'hidden';

  if (inputId) {
    const field = document.getElementById(inputId);
    field.style.borderColor = '';
  }
};

const postError = (message, inputId) => {
  const currentNote = selectNote();
  const noteContainer = selectNoteContainer();
  const field = selectById(inputId);
  field.style.borderColor = RED;
  currentNote.style.color = RED;
  currentNote.innerText = message;
  noteContainer.style.visibility = 'visible';
  setTimeout(clearNote.bind(null, inputId), 5000);
};

export { clearNote, note, postError };
