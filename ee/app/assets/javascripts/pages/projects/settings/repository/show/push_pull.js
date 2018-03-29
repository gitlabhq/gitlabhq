export default {
  init() {
    this.mirrorDirectionSelect = document.querySelector('.js-mirror-direction');
    this.insertionPoint = document.querySelector('.js-form-insertion-point');
    this.urlInput = document.querySelector('.js-mirror-url');
    this.protectedBranchesInput = document.querySelector('.js-mirror-protected');

    this.directionFormMap = {
      push: document.querySelector('.js-push-mirrors-form').innerHTML,
      pull: document.querySelector('.js-pull-mirrors-form').innerHTML,
    };

    this.boundUpdatedForm = this.updateForm.bind(this);

    this.boundUpdatedForm();
    this.registerUpdateListeners();
  },

  updateForm() {
    this.insertionPoint.innerHTML = this.directionFormMap[this.mirrorDirectionSelect.value];

    setTimeout(() => {
      document.querySelector('.js-mirror-url-hidden').value = this.urlInput.value;
      document.querySelector('.js-mirror-protected-hidden').value = this.protectedBranchesInput.checked ? this.protectedBranchesInput.value : '0';
    }, 0);
  },

  registerUpdateListeners() {
    this.mirrorDirectionSelect.addEventListener('change', this.boundUpdatedForm);
    this.urlInput.addEventListener('change', this.boundUpdatedForm);
    this.protectedBranchesInput.addEventListener('change', this.boundUpdatedForm);
  },
};
