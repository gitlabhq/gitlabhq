import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import TaskList from '~/task_list';

describe('TaskList', () => {
  let taskList;
  let currentTarget;
  const taskListOptions = {
    selector: '.task-list',
    dataType: 'issue',
    fieldName: 'description',
    lockVersion: 2,
  };
  const createTaskList = () => new TaskList(taskListOptions);

  beforeEach(() => {
    setFixtures(`
      <div class="task-list">
        <div class="js-task-list-container">
          <ul data-sourcepos="5:1-5:11" class="task-list" dir="auto">
            <li data-sourcepos="5:1-5:11" class="task-list-item enabled">
              <input type="checkbox" class="task-list-item-checkbox" checked=""> markdown task
            </li>
          </ul>

          <ul class="task-list" dir="auto">
            <li class="task-list-item enabled">
              <input type="checkbox" class="task-list-item-checkbox"> hand-coded checkbox
            </li>
          </ul>
          <textarea class="hidden js-task-list-field"></textarea>
        </div>
      </div>
    `);

    currentTarget = $('<div></div>');
    taskList = createTaskList();
  });

  it('should call init when the class constructed', () => {
    jest.spyOn(TaskList.prototype, 'init');
    jest.spyOn(TaskList.prototype, 'disable').mockImplementation(() => {});
    jest.spyOn($.prototype, 'taskList').mockImplementation(() => {});
    jest.spyOn($.prototype, 'on').mockImplementation(() => {});

    taskList = createTaskList();
    const $taskListEl = $(taskList.taskListContainerSelector);

    expect(taskList.init).toHaveBeenCalled();
    expect(taskList.disable).toHaveBeenCalled();
    expect($taskListEl.taskList).toHaveBeenCalledWith('enable');
    expect($(document).on).toHaveBeenCalledWith(
      'tasklist:changed',
      taskList.taskListContainerSelector,
      taskList.updateHandler,
    );
  });

  describe('getTaskListTarget', () => {
    it('should return currentTarget from event object if exists', () => {
      const $target = taskList.getTaskListTarget({ currentTarget });

      expect($target).toEqual(currentTarget);
    });

    it('should return element of the taskListContainerSelector', () => {
      const $target = taskList.getTaskListTarget();

      expect($target).toEqual($(taskList.taskListContainerSelector));
    });
  });

  describe('disableTaskListItems', () => {
    it('should call taskList method with disable param', () => {
      taskList.disableTaskListItems();

      expect(document.querySelectorAll('.task-list-item input:disabled').length).toEqual(2);
    });
  });

  describe('enableTaskListItems', () => {
    it('should enable markdown tasks and disable non-markdown tasks', () => {
      taskList.disableTaskListItems();
      taskList.enableTaskListItems();

      expect(document.querySelectorAll('.task-list-item input:enabled').length).toEqual(1);
      expect(document.querySelectorAll('.task-list-item input:disabled').length).toEqual(1);
    });
  });

  describe('enable', () => {
    it('should enable task list items and on document event', () => {
      jest.spyOn($.prototype, 'on').mockImplementation(() => {});

      taskList.enable();

      expect(document.querySelectorAll('.task-list-item input:enabled').length).toEqual(1);
      expect(document.querySelectorAll('.task-list-item input:disabled').length).toEqual(1);

      expect($(document).on).toHaveBeenCalledWith(
        'tasklist:changed',
        taskList.taskListContainerSelector,
        taskList.updateHandler,
      );
    });
  });

  describe('disable', () => {
    it('should disable task list items and off document event', () => {
      jest.spyOn($.prototype, 'off').mockImplementation(() => {});

      taskList.disable();

      expect(document.querySelectorAll('.task-list-item input:disabled').length).toEqual(2);

      expect($(document).off).toHaveBeenCalledWith(
        'tasklist:changed',
        taskList.taskListContainerSelector,
      );
    });
  });

  describe('update', () => {
    it('should disable task list items and make a patch request then enable them again', (done) => {
      const response = { data: { lock_version: 3 } };
      jest.spyOn(taskList, 'enableTaskListItems').mockImplementation(() => {});
      jest.spyOn(taskList, 'disableTaskListItems').mockImplementation(() => {});
      jest.spyOn(taskList, 'onSuccess').mockImplementation(() => {});
      jest.spyOn(axios, 'patch').mockReturnValue(Promise.resolve(response));

      const value = 'hello world';
      const endpoint = '/foo';
      const target = $(`<input data-update-url="${endpoint}" value="${value}" />`);
      const detail = {
        index: 2,
        checked: true,
        lineNumber: 8,
        lineSource: '- [ ] check item',
      };
      const event = { target, detail };
      const patchData = {
        [taskListOptions.dataType]: {
          [taskListOptions.fieldName]: value,
          lock_version: taskListOptions.lockVersion,
          update_task: {
            index: detail.index,
            checked: detail.checked,
            line_number: detail.lineNumber,
            line_source: detail.lineSource,
          },
        },
      };

      taskList
        .update(event)
        .then(() => {
          expect(taskList.disableTaskListItems).toHaveBeenCalledWith(event);
          expect(axios.patch).toHaveBeenCalledWith(endpoint, patchData);
          expect(taskList.enableTaskListItems).toHaveBeenCalledWith(event);
          expect(taskList.onSuccess).toHaveBeenCalledWith(response.data);
          expect(taskList.lockVersion).toEqual(response.data.lock_version);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  it('should handle request error and enable task list items', (done) => {
    const response = { data: { error: 1 } };
    jest.spyOn(taskList, 'enableTaskListItems').mockImplementation(() => {});
    jest.spyOn(taskList, 'onError').mockImplementation(() => {});
    jest.spyOn(axios, 'patch').mockReturnValue(Promise.reject({ response })); // eslint-disable-line prefer-promise-reject-errors

    const event = { detail: {} };
    taskList
      .update(event)
      .then(() => {
        expect(taskList.enableTaskListItems).toHaveBeenCalledWith(event);
        expect(taskList.onError).toHaveBeenCalledWith(response.data);
      })
      .then(done)
      .catch(done.fail);
  });
});
