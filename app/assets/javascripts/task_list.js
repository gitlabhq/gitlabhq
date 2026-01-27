import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import axios from './lib/utils/axios_utils';
import { toggleCheckbox } from './behaviors/markdown/utils';

export default class TaskList {
  constructor(options = {}) {
    this.selector = options.selector;
    this.dataType = options.dataType;
    this.fieldName = options.fieldName;
    this.lockVersion = options.lockVersion;
    this.taskListContainerSelector = `${this.selector} .js-task-list-container`;
    this.updateHandler = this.update.bind(this);
    this.onUpdate = options.onUpdate || (() => {});
    this.onSuccess = options.onSuccess || (() => {});
    this.onError =
      options.onError ||
      function showFlash(e) {
        let errorMessages = '';

        if (e.response.data && typeof e.response.data === 'object') {
          errorMessages = e.response.data.errors.join(' ');
        }

        return createAlert({
          message: errorMessages || __('Update failed'),
        });
      };

    this.init();
  }

  init() {
    this.disable(); // Prevent duplicate event bindings

    const taskListFields = document.querySelectorAll(
      `${this.taskListContainerSelector} .js-task-list-field[data-value]`,
    );

    taskListFields.forEach((taskListField) => {
      // eslint-disable-next-line no-param-reassign
      taskListField.value = taskListField.dataset.value;
    });

    this.enable();
  }

  getTaskListTargets(inputElement) {
    if (!inputElement) return Array.from(document.querySelectorAll(this.taskListContainerSelector));
    return [inputElement.closest(this.taskListContainerSelector)];
  }

  disableTaskListItems(inputElement) {
    this.getTaskListTargets(inputElement).forEach((taskListContainer) => {
      taskListContainer.querySelectorAll('.task-list-item').forEach((taskListItem) => {
        taskListItem.classList.remove('enabled');
      });
      taskListContainer
        .querySelectorAll('.task-list-item-checkbox')
        .forEach((taskListItemCheckbox) => {
          // eslint-disable-next-line no-param-reassign
          taskListItemCheckbox.disabled = true;
        });
    });
  }

  enableTaskListItems(inputElement) {
    this.getTaskListTargets(inputElement).forEach((taskListContainer) => {
      // Ensure there is a corresponding textarea field before enabling.
      if (!taskListContainer.querySelector('.js-task-list-field')) return;

      taskListContainer.querySelectorAll('.task-list-item').forEach((taskListItem) => {
        taskListItem.classList.add('enabled');
      });
      taskListContainer
        .querySelectorAll(
          `.task-list-item[data-sourcepos] .task-list-item-checkbox:not([data-inapplicable]),
         .task-list-item-checkbox[data-checkbox-sourcepos]:not([data-inapplicable])`,
        )
        .forEach((taskListItemCheckbox) => {
          // eslint-disable-next-line no-param-reassign
          taskListItemCheckbox.disabled = false;
        });
    });
  }

  enable() {
    this.enableTaskListItems();
    document.addEventListener('change', this.updateHandler);
  }

  disable() {
    this.disableTaskListItems();
    document.removeEventListener('change', this.updateHandler);
  }

  update(e) {
    const container = e.target.closest(this.taskListContainerSelector);
    if (!container) return null;

    if (!e.target.classList.contains('task-list-item-checkbox')) return null;

    const { checked } = e.target;

    const field = container.querySelector('.js-task-list-field');
    const replacement = toggleCheckbox({
      rawMarkdown: field.value,
      checkboxChecked: checked,
      target: e.target,
    });

    field.value = replacement.newMarkdown;

    const patchData = {};

    const dataType = this.dataType === TYPE_INCIDENT ? TYPE_ISSUE : this.dataType;
    patchData[dataType] = {
      [this.fieldName]: field.value,
      lock_version: this.lockVersion,
      update_task: {
        checked,
        line_source: replacement.oldLine,
        line_sourcepos: replacement.sourcepos,
      },
    };

    this.onUpdate();
    this.disableTaskListItems(e.target);

    return axios
      .patch(
        field.dataset.updateUrl || document.querySelector('form.js-issuable-update').action,
        patchData,
      )
      .then(({ data }) => {
        this.lockVersion = data.lock_version;
        this.enableTaskListItems(e.target);

        return this.onSuccess(data);
      })
      .catch(({ response }) => {
        this.enableTaskListItems(e.target);

        return this.onError(response.data);
      });
  }
}
