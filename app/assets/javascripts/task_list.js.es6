require('vendor/task_list');

class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    // Prevent duplicate event bindings
    this.disable();
    this.init();
  }

  init() {
    $(this.selector + ' .js-task-list-container').taskList('enable');
    $(document).on('tasklist:changed', this.selector + ' .js-task-list-container', this.update.bind(this));
  }

  disable() {
    $(this.selector + ' .js-task-list-container').taskList('disable');
    return $(document).off('tasklist:changed', this.selector + ' .js-task-list-container');
  }

  update(e) {
    var patchData;
    patchData = {};
    patchData[this.dataType] = {
      'description': $(e.target).val()
    };
    return $.ajax({
      type: 'PATCH',
      url: $('form.js-issuable-update').attr('action'),
      data: patchData,
      success: function(result) {
        document.querySelector('#task_status').innerText = result.task_status;
        document.querySelector('#task_status_short').innerText = result.task_status_short;
      }
    });
  // TODO (rspeicher): Make the issue description inline-editable like a note so
  // that we can re-use its form here
  }
}

window.gl = window.gl || {};
window.gl.TaskList = TaskList;
