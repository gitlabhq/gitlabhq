import $ from 'jquery';
import { __ } from '~/locale';
import Flash from '~/flash';
import PushPull from '~/pages/projects/settings/repository/show/push_pull';
import MirrorPull from 'ee/mirrors/mirror_pull';

export default class EEPushPull extends PushPull {
  constructor(...args) {
    super(...args);

    this.$mirrorDirectionSelect = $('.js-mirror-direction', this.$form);
    this.$insertionPoint = $('.js-form-insertion-point', this.$form);
    this.$repoCount = $('.js-mirrored-repo-count', this.$container);
    this.directionFormMap = {
      push: $('.js-push-mirrors-form', this.$form).html(),
      pull: $('.js-pull-mirrors-form', this.$form).html(),
    };
  }

  init() {
    this.handleUpdate();
    super.init();
  }

  handleUpdate() {
    return this.hideForm()
      .then(() => {
        this.updateForm();

        this.$insertionPoint.collapse('show');
      })
      .catch(() => {
        Flash(__('Something went wrong on our end.'));
      });
  }

  hideForm() {
    return new Promise(resolve => {
      if (!this.$insertionPoint.hasClass('in')) return resolve();

      return this.$insertionPoint.collapse('hide').one('hidden.bs.collapse', () => resolve());
    });
  }

  updateForm() {
    const direction = this.$mirrorDirectionSelect.val();

    this.$insertionPoint.html(this.directionFormMap[direction]);

    this.updateUrl();
    this.updateProtectedBranches();

    if (direction === 'pull') this.initMirrorPull();
  }

  initMirrorPull() {
    const mirrorPull = new MirrorPull('.js-mirror-form');

    if (this.$urlInput.val() !== '') mirrorPull.handleRepositoryUrlInput();
    mirrorPull.init();

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

    super.deleteMirror(event, payload);
  }

  removeRow($target) {
    super.removeRow($target);

    const currentCount = parseInt(this.$repoCount.text().replace(/(\(|\))/, ''), 10);
    this.$repoCount.text(`(${currentCount - 1})`);
  }
}
