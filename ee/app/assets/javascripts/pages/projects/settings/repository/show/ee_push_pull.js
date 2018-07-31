import $ from 'jquery';
import { __ } from '~/locale';
import Flash from '~/flash';
import PushPull from '~/pages/projects/settings/repository/show/push_pull';
import MirrorPull from 'ee/mirrors/mirror_pull';

export default class EEPushPull extends PushPull {
  constructor(...args) {
    super(...args);

    this.$password = undefined;
    this.$mirrorDirectionSelect = $('.js-mirror-direction', this.$form);
    this.$insertionPoint = $('.js-form-insertion-point', this.$form);
    this.$repoCount = $('.js-mirrored-repo-count', this.$container);
    this.directionFormMap = {
      push: $('.js-push-mirrors-form', this.$form).html(),
      pull: $('.js-pull-mirrors-form', this.$form).html(),
    };
  }

  init() {
    this.$insertionPoint.collapse({
      toggle: false,
    });
    this.handleUpdate();
    super.init();
  }

  updateUrl() {
    let val = this.$urlInput.val();

    if (this.$password) {
      const password = this.$password.val();
      if (password) val = val.replace('@', `:${password}@`);
    }

    $('.js-mirror-url-hidden', this.$form).val(val);
  }

  handleUpdate() {
    return this.hideForm()
      .then(() => {
        this.updateForm();
        this.showForm();
      })
      .catch(() => {
        Flash(__('Something went wrong on our end.'));
      });
  }

  hideForm() {
    return new Promise(resolve => {
      if (!this.$insertionPoint.html()) return resolve();

      this.$insertionPoint.one('hidden.bs.collapse', () => {
        resolve();
      });
      return this.$insertionPoint.collapse('hide');
    });
  }

  showForm() {
    return new Promise(resolve => {
      this.$insertionPoint.one('shown.bs.collapse', () => {
        resolve();
      });
      this.$insertionPoint.collapse('show');
    });
  }

  updateForm() {
    const direction = this.$mirrorDirectionSelect.val();

    this.$insertionPoint.html(this.directionFormMap[direction]);

    this.updateUrl();
    this.updateProtectedBranches();

    if (direction === 'pull') return this.initMirrorPull();
    return this.initMirrorPush();
  }

  initMirrorPull() {
    this.$password.off('input.updateUrl');
    this.$password = undefined;

    const mirrorPull = new MirrorPull('.js-mirror-form');

    if (this.$urlInput.val() !== '') mirrorPull.handleRepositoryUrlInput();
    mirrorPull.init();

    this.initSelect2();
  }

  initMirrorPush() {
    this.$password = $('.js-password', this.$form);
    this.$password.on('input.updateUrl', () => this.debouncedUpdateUrl());
  }

  initSelect2() {
    $('.js-mirror-user', this.$form).select2({
      width: 'resolve',
      dropdownAutoWidth: true,
    });
  }

  registerUpdateListeners() {
    super.registerUpdateListeners();
    this.$mirrorDirectionSelect.on('change', () => this.handleUpdate());
  }

  deleteMirror(event) {
    const $target = $(event.currentTarget);
    const isPullMirror = $target.hasClass('js-delete-pull-mirror');
    let payload;

    if (isPullMirror) {
      payload = {
        project: {
          mirror: false,
        },
      };
    }

    super.deleteMirror(event, payload);
  }

  removeRow($target) {
    super.removeRow($target);

    const currentCount = parseInt(this.$repoCount.text().replace(/(\(|\))/, ''), 10);
    this.$repoCount.text(`(${currentCount - 1})`);
  }
}
