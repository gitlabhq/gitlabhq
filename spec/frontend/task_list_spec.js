import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
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
    setHTMLFixture(`
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

  afterEach(() => {
    resetHTMLFixture();
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
    const setupTaskListAndMocks = (options) => {
      taskList = new TaskList(options);

      jest.spyOn(taskList, 'enableTaskListItems').mockImplementation(() => {});
      jest.spyOn(taskList, 'disableTaskListItems').mockImplementation(() => {});
      jest.spyOn(taskList, 'onUpdate').mockImplementation(() => {});
      jest.spyOn(taskList, 'onSuccess').mockImplementation(() => {});
      jest.spyOn(axios, 'patch').mockResolvedValue({ data: { lock_version: 3 } });

      return taskList;
    };

    const performTest = (options) => {
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
      const dataType = options.dataType === 'incident' ? 'issue' : options.dataType;
      const patchData = {
        [dataType]: {
          [options.fieldName]: value,
          lock_version: options.lockVersion,
          update_task: {
            index: detail.index,
            checked: detail.checked,
            line_number: detail.lineNumber,
            line_source: detail.lineSource,
          },
        },
      };

      const update = taskList.update(event);

      expect(taskList.onUpdate).toHaveBeenCalled();

      return update.then(() => {
        expect(taskList.disableTaskListItems).toHaveBeenCalledWith(event);
        expect(axios.patch).toHaveBeenCalledWith(endpoint, patchData);
        expect(taskList.enableTaskListItems).toHaveBeenCalledWith(event);
        expect(taskList.onSuccess).toHaveBeenCalledWith({ lock_version: 3 });
        expect(taskList.lockVersion).toEqual(3);
      });
    };

    it('should disable task list items and make a patch request then enable them again', () => {
      taskList = setupTaskListAndMocks(taskListOptions);

      return performTest(taskListOptions);
    });

    describe('for merge requests', () => {
      it('should wrap the patch request payload in merge_request', () => {
        const options = {
          selector: '.task-list',
          dataType: 'merge_request',
          fieldName: 'description',
          lockVersion: 2,
        };
        taskList = setupTaskListAndMocks(options);

        return performTest(options);
      });
    });

    describe('for incidents', () => {
      it('should wrap the patch request payload in issue', () => {
        const options = {
          selector: '.task-list',
          dataType: 'incident',
          fieldName: 'description',
          lockVersion: 2,
        };
        taskList = setupTaskListAndMocks(options);

        return performTest(options);
      });
    });
  });

  it('should handle request error and enable task list items', () => {
    const response = { data: { error: 1 } };
    jest.spyOn(taskList, 'enableTaskListItems').mockImplementation(() => {});
    jest.spyOn(taskList, 'onUpdate').mockImplementation(() => {});
    jest.spyOn(taskList, 'onError').mockImplementation(() => {});
    jest.spyOn(axios, 'patch').mockReturnValue(Promise.reject({ response })); // eslint-disable-line prefer-promise-reject-errors

    const event = { detail: {} };

    const update = taskList.update(event);

    expect(taskList.onUpdate).toHaveBeenCalled();

    return update.then(() => {
      expect(taskList.enableTaskListItems).toHaveBeenCalledWith(event);
      expect(taskList.onError).toHaveBeenCalledWith(response.data);
    });
  });
});
