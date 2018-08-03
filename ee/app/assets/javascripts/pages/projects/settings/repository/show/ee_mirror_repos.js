import $ from 'jquery';
import { __ } from '~/locale';
import Flash from '~/flash';
import MirrorRepos from '~/pages/projects/settings/repository/show/mirror_repos';
import MirrorPull from 'ee/mirrors/mirror_pull';

export default class EEMirrorRepos extends MirrorRepos {
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

    this.$insertionPoint.collapse('hide');
    this.$insertionPoint.html(this.directionFormMap[direction]);
    this.$insertionPoint.collapse('show');

    this.updateUrl();
    this.updateProtectedBranches();

    if (direction === 'pull') return this.initMirrorPull();
    this.mirrorPull.destroy();
    return this.initMirrorPush();
  }

  initMirrorPull() {
    this.$password.off('input.updateUrl');
    this.$password = undefined;

    this.mirrorPull = new MirrorPull('.js-mirror-form');
    this.mirrorPull.init();

    this.initSelect2();
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

    return super.deleteMirror(event, payload)
      .then(() => {
        if (isPullMirror) this.$mirrorDirectionSelect.removeAttr('disabled');
      });
  }

  removeRow($target) {
    super.removeRow($target);

    const currentCount = parseInt(this.$repoCount.text().replace(/(\(|\))/, ''), 10);
    this.$repoCount.text(`(${currentCount - 1})`);
  }
}
