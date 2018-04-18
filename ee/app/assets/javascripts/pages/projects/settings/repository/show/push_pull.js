import $ from 'jquery';
import _ from 'underscore';
import 'bootstrap-sass/assets/javascripts/bootstrap/collapse';
import MirrorPull from 'ee/mirrors/mirror_pull';
import { __ } from '~/locale';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { renderTimeago } from '~/lib/utils/datetime_utility';

export default {
  init(container) {
    this.container = container;
    this.form = container.querySelector('.js-mirror-form');
    this.mirrorDirectionSelect = this.form.querySelector('.js-mirror-direction');
    this.$insertionPoint = $('.js-form-insertion-point', this.form);
    this.urlInput = this.form.querySelector('.js-mirror-url');
    this.protectedBranchesInput = this.form.querySelector('.js-mirror-protected');
    this.mirrorEndpoint = this.form.dataset.projectMirrorEndpoint;
    this.$table = $('.js-mirrors-table-body', this.container);
    this.trTemplate = _.template(this.container.querySelector('.js-tr-template').innerHTML);

    this.directionFormMap = {
      push: this.form.querySelector('.js-push-mirrors-form').innerHTML,
      pull: this.form.querySelector('.js-pull-mirrors-form').innerHTML,
    };

    this.boundUpdateForm = this.handleUpdate.bind(this);
    this.boundUpdateUrl = this.updateUrl.bind(this);
    this.boundUpdateProtectedBranches = this.updateProtectedBranches.bind(this);

    this.boundUpdateForm();
    this.registerUpdateListeners();

    $(this.$table)
      .on('click', '.js-delete-mirror', this.deleteMirror.bind(this));
    $('.js-add-mirror')
      .on('click', this.addMirror.bind(this));
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

  addMirror(event) {
    event.preventDefault();
    const direction = this.mirrorDirectionSelect.value;
    const isPull = this.mirrorDirectionSelect.value === 'pull';

    const payload = new FormData(this.form);
    return axios.post(this.form.action, payload)
      .then(({ data }) => {
        let safeUrl;
        let updatedAt;
        let id;

        debugger;

        if (isPull) {
          safeUrl = data.username_only_import_url;
          updatedAt = data.mirror_last_update_at;
        } else {
          const mirror = data.remote_mirrors_attributes[0];
          safeUrl = mirror.safe_url;
          updatedAt = mirror.last_update_at;
        }

        const insertDirection = isPull ? this.$table.prepend : this.$table.append;

        const $tr = insertDirection(this.trTemplate({
          direction,
          safeUrl,
          updatedAt,
          id,
        }));

        renderTimeago($('.js-mirror-timeago', $tr));
      })
      .catch(() => Flash(__('Failed to add mirror.')));
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
          id: target.dataset.mirrorId,
          enabled: 0,
        },
      };
    }

    return axios.put(this.mirrorEndpoint, payload)
      .then(() => {
        $(target).closest('tr').remove();
      })
      .catch(() => Flash(__('Failed to remove mirror.')));
  },
};
