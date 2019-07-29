import { CLEAR, FORM, FORM_CONTAINER, WHITE } from '../shared';
import {
  selectCollapseButton,
  selectForm,
  selectFormContainer,
  selectNoteContainer,
} from './utils';
import { collapseButton, commentIcon, compressIcon } from './wrapper_icons';

const form = content => `
  <form id="${FORM}" novalidate>
    ${content}
  </form>
`;

const buttonAndForm = content => `
  <div id="${FORM_CONTAINER}" class="gitlab-form-open">
    ${collapseButton}
    ${form(content)}
  </div>
`;

const addForm = nextForm => {
  const formWrapper = selectForm();
  formWrapper.innerHTML = nextForm;
};

function toggleForm() {
  const toggleButton = selectCollapseButton();
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

  const nextState = toggleButton.classList.contains('gitlab-collapse-open') ? CLOSED : OPEN;
  const currentVals = stateVals[nextState];

  formContainer.classList.replace(...currentVals.containerClasses);
  formContainer.style.backgroundColor = currentVals.backgroundColor;
  formContainer.classList.toggle('gitlab-form-open');
  currentForm.style.display = currentVals.display;
  toggleButton.classList.replace(...currentVals.buttonClasses);
  toggleButton.innerHTML = currentVals.icon;

  if (noteContainer && noteContainer.innerText.length > 0) {
    noteContainer.style.display = currentVals.display;
  }
}

export { addForm, buttonAndForm, toggleForm };
