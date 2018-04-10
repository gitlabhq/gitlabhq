import $ from 'jquery';
import 'deckar01-task_list';
import axios from './lib/utils/axios_utils';
import Flash from './flash';

export default class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    this.fieldName = options.fieldName;
    this.onSuccess = options.onSuccess || (() => {});
    this.onError = function showFlash(e) {
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

    return axios.patch($target.data('updateUrl') || $('form.js-issuable-update').attr('action'), patchData)
      .then(({ data }) => this.onSuccess(data))
      .catch(err => this.onError(err));
  }
}
