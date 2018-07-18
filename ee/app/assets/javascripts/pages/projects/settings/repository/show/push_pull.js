import $ from 'jquery';
import _ from 'underscore';
import MirrorPull from 'ee/mirrors/mirror_pull';
import { __ } from '~/locale';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';

export default {
  init(container) {
    this.$container = $(container);
    this.$form = $('.js-mirror-form', this.$container);
    this.$mirrorDirectionSelect = $('.js-mirror-direction', this.$form);
    this.$insertionPoint = $('.js-form-insertion-point', this.$form);
    this.$urlInput = $('.js-mirror-url', this.$form);
    this.$protectedBranchesInput = $('.js-mirror-protected', this.$form);
    this.mirrorEndpoint = this.$form.data('projectMirrorEndpoint');
    this.$table = $('.js-mirrors-table-body', this.$container);
    this.$repoCount = $('.js-mirrored-repo-count', this.$container);
    this.trTemplate = _.template($('.js-tr-template', this.$container).html());

    this.directionFormMap = {
      push: $('.js-push-mirrors-form', this.$form).html(),
      pull: $('.js-pull-mirrors-form', this.$form).html(),
    };

    this.handleUpdate();
    this.registerUpdateListeners();

    this.$table.on('click', '.js-delete-mirror', this.deleteMirror.bind(this));
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
    const direction = this.$mirrorDirectionSelect.val();

    this.$insertionPoint.html(this.directionFormMap[direction]);

    this.updateUrl();
    this.updateProtectedBranches();

    if (direction !== 'pull') return;

    this.initMirrorPull();
  },

  updateUrl() {
    $('.js-mirror-url-hidden', this.$form).val(this.$urlInput.val());
  },

  updateProtectedBranches() {
    const val = this.$protectedBranchesInput.get(0).checked ? this.$protectedBranchesInput.val() : '0';
    $('.js-mirror-protected-hidden', this.$form).val(val);
  },

  initMirrorPull() {
    const mirrorPull = new MirrorPull('.js-mirror-form');

    if (this.$urlInput.val() !== '') mirrorPull.handleRepositoryUrlInput();
    mirrorPull.init();

    this.initSelect2();
  },

  initSelect2() {
    $('.js-mirror-user', this.$form).select2({
      width: 'resolve',
      dropdownAutoWidth: true,
    });
  },

  registerUpdateListeners() {
    this.$mirrorDirectionSelect.on('change', () => this.handleUpdate());
    this.$urlInput.on('change', () => this.updateUrl());
    this.$protectedBranchesInput.on('change', () => this.updateProtectedBranches());
  },

  deleteMirror(event) {
    const $target = $(event.currentTarget);
    const isPullMirror = $target.hasClass('js-delete-pull-mirror');
    const payload = { project: {} };

    if (isPullMirror) {
      payload.project.mirror = false;
    } else {
      payload.project = {
        remote_mirrors_attributes: {
          id: $target.data('mirrorId'),
          enabled: 0,
        },
      };
    }

    return axios.put(this.mirrorEndpoint, payload)
      .then(() => {
        const row = $target.closest('tr');
        $('.js-delete-mirror', row).tooltip('hide');
        row.remove();
        const currentCount = parseInt(this.$repoCount.text().replace(/(\(|\))/, ''), 10);
        this.$repoCount.text(`(${currentCount - 1})`);
      })
      .catch(() => Flash(__('Failed to remove mirror.')));
  },
};
