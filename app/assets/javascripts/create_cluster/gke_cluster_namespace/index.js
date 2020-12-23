/**
 * Disables & hides the namespace inputs when the gitlab-managed checkbox is checked/unchecked.
 */

const setDisabled = (el, isDisabled) => {
  if (isDisabled) {
    el.classList.add('hidden');
    el.querySelector('input').setAttribute('disabled', true);
  } else {
    el.classList.remove('hidden');
    el.querySelector('input').removeAttribute('disabled');
  }
};

const setState = (glManagedCheckbox) => {
  const glManaged = document.querySelector('.js-namespace-prefixed');
  const selfManaged = document.querySelector('.js-namespace');

  if (glManagedCheckbox.checked) {
    setDisabled(glManaged, false);
    setDisabled(selfManaged, true);
  } else {
    setDisabled(glManaged, true);
    setDisabled(selfManaged, false);
  }
};

const initGkeNamespace = () => {
  const glManagedCheckbox = document.querySelector('.js-gl-managed');

  if (glManagedCheckbox) {
    setState(glManagedCheckbox); // this is needed in order to set the initial state
    glManagedCheckbox.addEventListener('change', () => setState(glManagedCheckbox));
  }
};

export default initGkeNamespace;
