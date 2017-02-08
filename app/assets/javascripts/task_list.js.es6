/* eslint-disable class-methods-use-this, no-new, func-names, prefer-template, no-unneeded-ternary, object-shorthand, space-before-function-paren, comma-dangle, quote-props, consistent-return, no-else-return, no-param-reassign, max-len */
/* global UsersSelect */

require('vendor/task_list');

class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    this.onSuccess = options.onSuccess || (() => {});
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
    return $(document).off('tasklist:changed', `${this.selector} .js-task-list-container`);
  }

  update(e) {
    const $target = $(e.target);
    const patchData = {};
    patchData[this.dataType] = {
      description: $target.val(),
    };
    return $.ajax({
      type: 'PATCH',
      url: $target.data('update-url') || $('form.js-issuable-update').attr('action'),
      data: patchData,
      success: this.onSuccess,
    });
  }
}

window.gl = window.gl || {};
window.gl.TaskList = TaskList;
