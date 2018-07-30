import $ from 'jquery';
import _ from 'underscore';
import { __ } from '~/locale';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';

export default class PushPull {
  constructor(container) {
    this.$container = $(container);
    this.$form = $('.js-mirror-form', this.$container);
    this.$urlInput = $('.js-mirror-url', this.$form);
    this.$protectedBranchesInput = $('.js-mirror-protected', this.$form);
    this.mirrorEndpoint = this.$form.data('projectMirrorEndpoint');
    this.$table = $('.js-mirrors-table-body', this.$container);
  }

  init() {
    this.registerUpdateListeners();

    this.$table.on('click', '.js-delete-mirror', this.deleteMirror.bind(this));
  }

  updateUrl() {
    $('.js-mirror-url-hidden', this.$form).val(this.$urlInput.val());
  }

  updateProtectedBranches() {
    const val = this.$protectedBranchesInput.get(0).checked
      ? this.$protectedBranchesInput.val()
      : '0';
    $('.js-mirror-protected-hidden', this.$form).val(val);
  }

  registerUpdateListeners() {
    this.debouncedUpdateUrl = _.debounce(() => this.updateUrl(), 200);
    this.$urlInput.on('input', () => this.debouncedUpdateUrl());
    this.$protectedBranchesInput.on('change', () => this.updateProtectedBranches());
  }

  deleteMirror(event, existingPayload) {
    const $target = $(event.currentTarget);
    let payload = existingPayload;

    if (!payload) {
      payload = {
        project: {
          remote_mirrors_attributes: {
            id: $target.data('mirrorId'),
            enabled: 0,
          },
        },
      };
    }

    return axios
      .put(this.mirrorEndpoint, payload)
      .then(() => this.removeRow($target))
      .catch(() => Flash(__('Failed to remove mirror.')));
  }

  /* eslint-disable class-methods-use-this */
  removeRow($target) {
    const row = $target.closest('tr');
    $('.js-delete-mirror', row).tooltip('hide');
    row.remove();
  }
  /* eslint-enable class-methods-use-this */
}
