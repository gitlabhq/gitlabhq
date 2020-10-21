import $ from 'jquery';
import 'deckar01-task_list';
import { __ } from '~/locale';
import axios from './lib/utils/axios_utils';
import { deprecatedCreateFlash as Flash } from './flash';

export default class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    this.fieldName = options.fieldName;
    this.lockVersion = options.lockVersion;
    this.taskListContainerSelector = `${this.selector} .js-task-list-container`;
    this.updateHandler = this.update.bind(this);
    this.onSuccess = options.onSuccess || (() => {});
    this.onError =
      options.onError ||
      function showFlash(e) {
        let errorMessages = '';

        if (e.response.data && typeof e.response.data === 'object') {
          errorMessages = e.response.data.errors.join(' ');
        }

        return new Flash(errorMessages || __('Update failed'), 'alert');
      };

    this.init();
  }

  init() {
    this.disable(); // Prevent duplicate event bindings

    const taskListFields = document.querySelectorAll(
      `${this.taskListContainerSelector} .js-task-list-field[data-value]`,
    );

    taskListFields.forEach(taskListField => {
      // eslint-disable-next-line no-param-reassign
      taskListField.value = taskListField.dataset.value;
    });

    $(this.taskListContainerSelector).taskList('enable');
    $(document).on('tasklist:changed', this.taskListContainerSelector, this.updateHandler);
  }

  getTaskListTarget(e) {
    return e && e.currentTarget ? $(e.currentTarget) : $(this.taskListContainerSelector);
  }

  disableTaskListItems(e) {
    this.getTaskListTarget(e).taskList('disable');
  }

  enableTaskListItems(e) {
    this.getTaskListTarget(e).taskList('enable');
  }

  disable() {
    this.disableTaskListItems();
    $(document).off('tasklist:changed', this.taskListContainerSelector);
  }

  update(e) {
    const $target = $(e.target);
    const { index, checked, lineNumber, lineSource } = e.detail;
    const patchData = {};

    patchData[this.dataType] = {
      [this.fieldName]: $target.val(),
      lock_version: this.lockVersion,
      update_task: {
        index,
        checked,
        line_number: lineNumber,
        line_source: lineSource,
      },
    };

    this.disableTaskListItems(e);

    return axios
      .patch($target.data('updateUrl') || $('form.js-issuable-update').attr('action'), patchData)
      .then(({ data }) => {
        this.lockVersion = data.lock_version;
        this.enableTaskListItems(e);

        return this.onSuccess(data);
      })
      .catch(({ response }) => {
        this.enableTaskListItems(e);

        return this.onError(response.data);
      });
  }
}
