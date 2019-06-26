import { comment } from './comment';
import { CLEAR, FORM, FORM_CONTAINER, WHITE } from './constants';
import { login } from './login';
import { clearNote } from './note';
import {
  selectCollapseButton,
  selectForm,
  selectFormContainer,
  selectNoteContainer,
} from './utils';
import { commentIcon, compressIcon } from './wrapper_icons';

const form = content => `
  <form id="${FORM}">
    ${content}
  </form>
`;

const buttonAndForm = ({ content, toggleButton }) => `
  <div id="${FORM_CONTAINER}" class="gitlab-form-open">
    ${toggleButton}
    ${form(content)}
  </div>
`;

const addCommentForm = () => {
  const formWrapper = selectForm();
  formWrapper.innerHTML = comment;
};

const addLoginForm = () => {
  const formWrapper = selectForm();
  formWrapper.innerHTML = login;
};

function logoutUser() {
  const { localStorage } = window;

  // All the browsers we support have localStorage, so let's silently fail
  // and go on with the rest of the functionality.
  try {
    localStorage.removeItem('token');
  } catch (err) {
    return;
  }

  clearNote();
  addLoginForm();
}

function toggleForm() {
  const collapseButton = selectCollapseButton();
  const currentForm = selectForm();
  const formContainer = selectFormContainer();
  const noteContainer = selectNoteContainer();
  const OPEN = 'open';
  const CLOSED = 'closed';

  /*
    You may wonder why we spread the arrays before we reverse them.
    In the immortal words of MDN,
    Careful: reverse is destructive. It also changes the original array
  */

  const openButtonClasses = ['gitlab-collapse-closed', 'gitlab-collapse-open'];
  const closedButtonClasses = [...openButtonClasses].reverse();
  const openContainerClasses = ['gitlab-wrapper-closed', 'gitlab-wrapper-open'];
  const closedContainerClasses = [...openContainerClasses].reverse();

  const stateVals = {
    [OPEN]: {
      buttonClasses: openButtonClasses,
      containerClasses: openContainerClasses,
      icon: compressIcon,
      display: 'flex',
      backgroundColor: WHITE,
    },
    [CLOSED]: {
      buttonClasses: closedButtonClasses,
      containerClasses: closedContainerClasses,
      icon: commentIcon,
      display: 'none',
      backgroundColor: CLEAR,
    },
  };

  const nextState = collapseButton.classList.contains('gitlab-collapse-open') ? CLOSED : OPEN;
  const currentVals = stateVals[nextState];

  formContainer.classList.replace(...currentVals.containerClasses);
  formContainer.style.backgroundColor = currentVals.backgroundColor;
  formContainer.classList.toggle('gitlab-form-open');
  currentForm.style.display = currentVals.display;
  collapseButton.classList.replace(...currentVals.buttonClasses);
  collapseButton.innerHTML = currentVals.icon;

  if (noteContainer && noteContainer.innerText.length > 0) {
    noteContainer.style.display = currentVals.display;
  }
}

export { addCommentForm, addLoginForm, buttonAndForm, logoutUser, toggleForm };
