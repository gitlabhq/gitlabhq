import { comment } from './comment';
import { CLEAR, FORM, WHITE } from './constants';
import { login } from './login';
import { selectCollapseButton, selectContainer, selectForm } from './utils';
import { commentIcon, compressIcon } from './wrapper_icons';

const form = content => `
  <form id=${FORM}>
    ${content}
  </form>
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

  addLoginForm();
}

function toggleForm() {
  const container = selectContainer();
  const collapseButton = selectCollapseButton();
  const currentForm = selectForm();
  const OPEN = 'open';
  const CLOSED = 'closed';

  /*
    You may wonder why we spread the arrays before we reverse them.
    In the immortal words of MDN,
    Careful: reverse is destructive. It also changes the original array
  */

  const openButtonClasses = ['gitlab-collapse-closed', 'gitlab-collapse-open'];
  const closedButtonClasses = [...openButtonClasses].reverse();
  const openContainerClasses = ['gitlab-closed-wrapper', 'gitlab-open-wrapper'];
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

  container.classList.replace(...currentVals.containerClasses);
  container.style.backgroundColor = currentVals.backgroundColor;
  currentForm.style.display = currentVals.display;
  collapseButton.classList.replace(...currentVals.buttonClasses);
  collapseButton.innerHTML = currentVals.icon;
}

export { addCommentForm, addLoginForm, form, logoutUser, toggleForm };
