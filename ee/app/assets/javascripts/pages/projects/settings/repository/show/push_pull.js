import MirrorPull from 'ee/mirrors/mirror_pull';

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

    this.boundUpdateForm = this.updateForm.bind(this);
    this.boundUpdateUrl = this.updateUrl.bind(this);
    this.boundUpdateProtectedBranches = this.updateProtectedBranches.bind(this);

    this.boundUpdateForm();
    this.registerUpdateListeners();
  },

  updateForm() {
    const direction = this.mirrorDirectionSelect.value;
    this.insertionPoint.innerHTML = this.directionFormMap[direction];

    setTimeout(() => {
      this.updateUrl();
      this.updateProtectedBranches();

      if (direction !== 'pull') return;

      this.initMirrorPull();
    }, 0);
  },

  updateUrl() {
    document.querySelector('.js-mirror-url-hidden').value = this.urlInput.value;
  },

  updateProtectedBranches() {
    document.querySelector('.js-mirror-protected-hidden').value = this.protectedBranchesInput.checked ? this.protectedBranchesInput.value : '0';
  },

  initMirrorPull() {
    const mirrorPull = new MirrorPull('.js-mirror-form');

    if (mirrorPull) mirrorPull.init();
  },

  registerUpdateListeners() {
    this.mirrorDirectionSelect.addEventListener('change', this.boundUpdateForm);
    this.urlInput.addEventListener('change', this.boundUpdateUrl);
    this.protectedBranchesInput.addEventListener('change', this.boundUpdateProtectedBranches);
  },
};
