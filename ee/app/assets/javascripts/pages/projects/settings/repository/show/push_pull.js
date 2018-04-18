import $ from 'jquery';
import 'bootstrap-sass/assets/javascripts/bootstrap/collapse';
import MirrorPull from 'ee/mirrors/mirror_pull';
import { __ } from '~/locale';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';

export default {
  init(form) {
    this.form = form;
    this.mirrorDirectionSelect = form.querySelector('.js-mirror-direction');
    this.$insertionPoint = $('.js-form-insertion-point', form);
    this.urlInput = form.querySelector('.js-mirror-url');
    this.protectedBranchesInput = form.querySelector('.js-mirror-protected');
    this.mirrorEndpoint = form.dataset.projectMirrorEndpoint;

    this.directionFormMap = {
      push: form.querySelector('.js-push-mirrors-form').innerHTML,
      pull: form.querySelector('.js-pull-mirrors-form').innerHTML,
    };

    this.boundUpdateForm = this.handleUpdate.bind(this);
    this.boundUpdateUrl = this.updateUrl.bind(this);
    this.boundUpdateProtectedBranches = this.updateProtectedBranches.bind(this);

    this.boundUpdateForm();
    this.registerUpdateListeners();
    $('.js-mirrored-repositories-table')
      .on('click', '.js-delete-mirror', this.deleteMirror.bind(this));
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
    this.form.querySelector('.js-mirror-url-hidden').value = this.urlInput.value;
  },

  updateProtectedBranches() {
    this.form.querySelector('.js-mirror-protected-hidden').value = this.protectedBranchesInput.checked ? this.protectedBranchesInput.value : '0';
  },

  initMirrorPull() {
    const mirrorPull = new MirrorPull('.js-mirror-form');

    if (!mirrorPull) return;

    if (this.urlInput.value !== '') mirrorPull.handleRepositoryUrlInput();
    mirrorPull.init();

    this.initSelect2();
  },

  initSelect2() {
    $('.js-mirror-user', this.form).select2({
      width: 'resolve',
      dropdownAutoWidth: true,
    });
  },

  registerUpdateListeners() {
    this.mirrorDirectionSelect.addEventListener('change', this.boundUpdateForm);
    this.urlInput.addEventListener('change', this.boundUpdateUrl);
    this.protectedBranchesInput.addEventListener('change', this.boundUpdateProtectedBranches);
  },

  addMirror() {

  },

  deleteMirror(event) {
    const target = event.currentTarget;
    const isPullMirror = target.classList.contains('js-delete-pull-mirror');
    const payload = { project: {} };

    if (isPullMirror) {
      payload.project.mirror = false;
    } else {
      payload.project = {
        remote_mirrors_attributes: {
          id: target.dataset.mirrorIndex,
          enabled: 0,
        },
      };
    }

    return axios.put(this.mirrorEndpoint, payload);
  },
};
