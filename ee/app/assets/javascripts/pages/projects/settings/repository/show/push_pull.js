import $ from 'jquery';
import 'bootstrap-sass/assets/javascripts/bootstrap/collapse';
import MirrorPull from 'ee/mirrors/mirror_pull';
import { __ } from '~/locale';
import Flash from '~/flash';

export default {
  init(container) {
    this.container = container;
    this.mirrorDirectionSelect = container.querySelector('.js-mirror-direction');
    this.$insertionPoint = $('.js-form-insertion-point', container);
    this.urlInput = container.querySelector('.js-mirror-url');
    this.protectedBranchesInput = container.querySelector('.js-mirror-protected');

    this.directionFormMap = {
      push: container.querySelector('.js-push-mirrors-form').innerHTML,
      pull: container.querySelector('.js-pull-mirrors-form').innerHTML,
    };

    this.boundUpdateForm = this.handleUpdate.bind(this);
    this.boundUpdateUrl = this.updateUrl.bind(this);
    this.boundUpdateProtectedBranches = this.updateProtectedBranches.bind(this);

    this.boundUpdateForm();
    this.registerUpdateListeners();
  },

  handleUpdate() {
    return this.hideForm()
      .then(() => {
        this.updateForm();

        this.$insertionPoint.collapse('show');
      })
      .catch(() => {
        Flash(__('Something went wrong on our end.'));
      });
  },

  hideForm() {
    return new Promise((resolve) => {
      if (!this.$insertionPoint.hasClass('in')) return resolve();

      return this.$insertionPoint.collapse('hide')
        .one('hidden.bs.collapse', () => resolve());
    });
  },

  updateForm() {
    const direction = this.mirrorDirectionSelect.value;

    this.$insertionPoint.html(this.directionFormMap[direction]);

    this.updateUrl();
    this.updateProtectedBranches();

    if (direction !== 'pull') return;

    this.initMirrorPull();
  },

  updateUrl() {
    this.container.querySelector('.js-mirror-url-hidden').value = this.urlInput.value;
  },

  updateProtectedBranches() {
    this.container.querySelector('.js-mirror-protected-hidden').value = this.protectedBranchesInput.checked ? this.protectedBranchesInput.value : '0';
  },

  initMirrorPull() {
    const mirrorPull = new MirrorPull('.js-mirror-form');

    if (!mirrorPull) return;

    mirrorPull.handleRepositoryUrlInput();
    mirrorPull.init();

    this.initSelect2();
  },

  initSelect2() {
    $('.js-mirror-user', this.container).select2({
      width: 'resolve',
      dropdownAutoWidth: true,
    });
  },

  registerUpdateListeners() {
    this.mirrorDirectionSelect.addEventListener('change', this.boundUpdateForm);
    this.urlInput.addEventListener('change', this.boundUpdateUrl);
    this.protectedBranchesInput.addEventListener('change', this.boundUpdateProtectedBranches);
  },
};
