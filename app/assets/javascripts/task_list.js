import $ from 'jquery';
import 'deckar01-task_list';
import axios from './lib/utils/axios_utils';
import Flash from './flash';

export default class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    this.fieldName = options.fieldName;
    this.lockVersion = options.lockVersion;
    this.onSuccess = options.onSuccess || (() => {});
    this.onError = options.onError || function showFlash(e) {
      let errorMessages = '';

      if (e.response.data && typeof e.response.data === 'object') {
        errorMessages = e.response.data.errors.join(' ');
      }

      return new Flash(errorMessages || 'Update failed', 'alert');
    };

    this.init();
  }

  init() {
    // Prevent duplicate event bindings
    this.disable();
    $(`${this.selector} .js-task-list-container`).taskList('enable');
    $(document).on(
      'tasklist:changed',
      `${this.selector} .js-task-list-container`,
      this.update.bind(this),
    );
  }

  disableTaskListItems() {
    $(`${this.selector} .js-task-list-container`).taskList('disable');
  }

  enableTaskListItems() {
    $(`${this.selector} .js-task-list-container`).taskList('enable');
  }

  disable() {
    this.disableTaskListItems();
    $(document).off('tasklist:changed', `${this.selector} .js-task-list-container`);
  }

  update(e) {
    const $target = $(e.target);
    const { lineNumber, lineSource } = e.detail;
    const patchData = {};

    patchData[this.dataType] = {
      [this.fieldName]: $target.val(),
      lock_version: this.lockVersion,
      update_task: {
        line_number: lineNumber,
        line_source: lineSource,
      },
    };

    this.disableTaskListItems();

    return axios
      .patch($target.data('updateUrl') || $('form.js-issuable-update').attr('action'), patchData)
      .then(({ data }) => {
        this.lockVersion = data.lock_version;
        this.enableTaskListItems();

        return this.onSuccess(data);
      })
      .catch(({ response }) => {
        this.enableTaskListItems();

        return this.onError(response.data);
      });
  }
}
