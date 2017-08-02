/* global Flash */

import 'deckar01-task_list';

export default class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    this.fieldName = options.fieldName;
    this.onSuccess = options.onSuccess || (() => {});
    this.onError = function showFlash(response) {
      let errorMessages = '';

      if (response.responseJSON) {
        errorMessages = response.responseJSON.errors.join(' ');
      }

      return new Flash(errorMessages || 'Update failed', 'alert');
    };

    this.init();
  }

  init() {
    // Prevent duplicate event bindings
    this.disable();
    $(`${this.selector} .js-task-list-container`).taskList('enable');
    $(document).on('tasklist:changed', `${this.selector} .js-task-list-container`, this.update.bind(this));
  }

  disable() {
    $(`${this.selector} .js-task-list-container`).taskList('disable');
    $(document).off('tasklist:changed', `${this.selector} .js-task-list-container`);
  }

  update(e) {
    const $target = $(e.target);
    const patchData = {};
    patchData[this.dataType] = {
      [this.fieldName]: $target.val(),
    };
    return $.ajax({
      type: 'PATCH',
      url: $target.data('update-url') || $('form.js-issuable-update').attr('action'),
      data: patchData,
      success: this.onSuccess,
      error: this.onError,
    });
  }
}
