/* eslint-disable class-methods-use-this, no-new, func-names, prefer-template, no-unneeded-ternary, object-shorthand, space-before-function-paren, comma-dangle, quote-props, consistent-return, no-else-return, no-param-reassign, max-len */
/* global UsersSelect */

require('vendor/task_list');

class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    this.update = options.update || this.update.bind(this);
    this.init();
  }

  init() {
    // Prevent duplicate event bindings
    this.disable();
    $(`${this.selector} .js-task-list-container`).taskList('enable');
    $(document).on('tasklist:changed', `${this.selector} .js-task-list-container`, this.update);
  }

  disable() {
    $(`${this.selector} .js-task-list-container`).taskList('disable');
    return $(document).off('tasklist:changed', `${this.selector} .js-task-list-container`);
  }

  update(e) {
    const patchData = {};
    patchData[this.dataType] = {
      description: $(e.target).val(),
    };
    return $.ajax({
      type: 'PATCH',
      url: $('form.js-issuable-update').attr('action'),
      data: patchData,
      success: (result) => {
        document.querySelector('#task_status').innerText = result.task_status;
        document.querySelector('#task_status_short').innerText = result.task_status_short;
      },
    });
  }
}

window.gl = window.gl || {};
window.gl.TaskList = TaskList;
