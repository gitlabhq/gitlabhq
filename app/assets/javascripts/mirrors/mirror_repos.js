import $ from 'jquery';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { hide } from '~/tooltips';
import SSHMirror from './ssh_mirror';

const PASSWORD_FIELD_SELECTOR = '.js-mirror-password-field';

export default class MirrorRepos {
  constructor(container) {
    this.$container = $(container);
    this.$password = null;
    this.$form = $('.js-mirror-form', this.$container);
    this.$urlInput = $('.js-mirror-url', this.$form);
    this.$protectedBranchesInput = $('.js-mirror-protected', this.$form);
    this.$table = $('.js-mirrors-table-body', this.$container);
    this.mirrorEndpoint = this.$form.data('projectMirrorEndpoint');
  }

  init() {
    this.initMirrorPush();
    this.registerUpdateListeners();
  }

  initMirrorPush() {
    this.$keepDivergentRefsInput = $('.js-mirror-keep-divergent-refs', this.$form);
    this.$passwordGroup = $('.js-password-group', this.$container);
    this.$password = $('.js-password', this.$passwordGroup);
    this.$authMethod = $('.js-auth-method', this.$form);
    this.$keepDivergentRefsInput.on('change', () => this.updateKeepDivergentRefs());
    this.$authMethod.on('change', () => this.togglePassword());
    this.$password.on('input.updateUrl', () => this.debouncedUpdateUrl());

    this.initMirrorSSH();
    this.updateProtectedBranches();
    this.updateKeepDivergentRefs();
    MirrorRepos.resetPasswordField();
  }

  static resetPasswordField() {
    if (document.querySelector(PASSWORD_FIELD_SELECTOR)) {
      document.querySelector(PASSWORD_FIELD_SELECTOR).value = '';
    }
  }

  initMirrorSSH() {
    if (this.$password) {
      // eslint-disable-next-line @gitlab/no-global-event-off
      this.$password.off('input.updateUrl');
    }
    this.$password = undefined;

    this.sshMirror = new SSHMirror('.js-mirror-form');
    this.sshMirror.init();
  }

  updateUrl() {
    let val = this.$urlInput.val();

    if (this.$password) {
      const password = this.$password.val();
      if (password) val = val.replace('@', `:${password}@`);
    }

    $('.js-mirror-url-hidden', this.$form).val(val);
  }

  updateProtectedBranches() {
    const val = this.$protectedBranchesInput.get(0).checked
      ? this.$protectedBranchesInput.val()
      : '0';
    $('.js-mirror-protected-hidden', this.$form).val(val);
  }

  updateKeepDivergentRefs() {
    const field = this.$keepDivergentRefsInput.get(0);

    // This field only exists after the form is switched to 'Push' mode
    if (field) {
      const val = field.checked ? this.$keepDivergentRefsInput.val() : '0';
      $('.js-mirror-keep-divergent-refs-hidden', this.$form).val(val);
    }
  }

  registerUpdateListeners() {
    this.debouncedUpdateUrl = debounce(() => this.updateUrl(), 200);
    this.$urlInput.on('input', () => this.debouncedUpdateUrl());
    this.$protectedBranchesInput.on('change', () => this.updateProtectedBranches());
    this.$table.on('click', '.js-delete-mirror', (event) => this.deleteMirror(event));
  }

  togglePassword() {
    const isPassword = this.$authMethod.val() === 'password';

    if (!isPassword) {
      this.$password.val('');
      this.updateUrl();
    }
    this.$passwordGroup.collapse(isPassword ? 'show' : 'hide');
  }

  deleteMirror(event, existingPayload) {
    const $target = $(event.currentTarget);
    let payload = existingPayload;

    if (!payload) {
      payload = {
        project: {
          remote_mirrors_attributes: {
            id: $target.data('mirrorId'),
            _destroy: 1,
          },
        },
      };
    }

    return axios
      .put(this.mirrorEndpoint, payload)
      .then(() => this.removeRow($target))
      .catch(() =>
        createAlert({
          message: __('Failed to remove mirror.'),
        }),
      );
  }

  /* eslint-disable class-methods-use-this */
  removeRow($target) {
    const row = $target.closest('tr');
    hide($('.js-delete-mirror', row));
    row.remove();
  }
  /* eslint-enable class-methods-use-this */
}
