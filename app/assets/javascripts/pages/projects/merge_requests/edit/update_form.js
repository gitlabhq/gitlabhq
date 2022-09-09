const findForm = () => document.querySelector('.merge-request-form');

const removeHiddenCheckbox = (node) => {
  const checkboxWrapper = node.closest('.form-check');
  const hiddenCheckbox = checkboxWrapper.querySelector('input[type="hidden"]');
  hiddenCheckbox.remove();
};

export default () => {
  const updateCheckboxes = () => {
    const checkboxes = document.querySelectorAll('.js-form-update');

    if (!checkboxes.length) return;

    checkboxes.forEach((checkbox) => {
      if (checkbox.checked) {
        removeHiddenCheckbox(checkbox);
      }
    });
  };

  findForm().addEventListener('submit', () => updateCheckboxes());
};
