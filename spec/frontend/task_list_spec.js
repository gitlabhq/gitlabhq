import AxiosMockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import TaskList from '~/task_list';

describe('TaskList', () => {
  let taskList;
  const taskListOptions = {
    selector: '.task-list',
    dataType: 'issue',
    fieldName: 'description',
    lockVersion: 2,
  };
  const createTaskList = () => new TaskList(taskListOptions);

  beforeEach(() => {
    setHTMLFixture(`
      <form class="js-issuable-update" action="/test/update">
        <div class="task-list">
          <div class="js-task-list-container">
            <ul data-sourcepos="1:1-1:19" class="task-list" dir="auto">
              <li data-sourcepos="1:1-1:19" class="task-list-item enabled">
                <input type="checkbox" class="task-list-item-checkbox" data-checkbox-sourcepos="1:4-1:4"> markdown task
              </li>
            </ul>

            <ul class="task-list" dir="auto">
              <li class="task-list-item enabled">
                <input type="checkbox" class="task-list-item-checkbox"> hand-coded checkbox
              </li>
            </ul>
            <textarea class="hidden js-task-list-field" data-value="* [ ] markdown task"></textarea>
          </div>
        </div>
      </form>
    `);

    taskList = createTaskList();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('should call init when the class constructed', () => {
    jest.spyOn(TaskList.prototype, 'init');
    jest.spyOn(TaskList.prototype, 'disable').mockImplementation(() => {});
    jest.spyOn(TaskList.prototype, 'enable').mockImplementation(() => {});

    taskList = createTaskList();

    expect(taskList.init).toHaveBeenCalled();
    expect(taskList.disable).toHaveBeenCalled();
    expect(taskList.enable).toHaveBeenCalled();
  });

  describe('getTaskListTargets', () => {
    it('should return the container holding the input if given', () => {
      const container = document.querySelector(taskList.taskListContainerSelector);
      const field = document.querySelector('.js-task-list-field');

      const targets = taskList.getTaskListTargets(field);
      expect(targets).toEqual([container]);
    });

    it('should return all task list containers if no input given', () => {
      const targets = taskList.getTaskListTargets();

      expect(targets).toHaveLength(1);
      expect(targets[0]).toEqual(document.querySelector(taskList.taskListContainerSelector));
    });
  });

  describe('disableTaskListItems', () => {
    it('should call taskList method with disable param', () => {
      taskList.disableTaskListItems();

      expect(document.querySelectorAll('.task-list-item input:disabled')).toHaveLength(2);
    });
  });

  describe('enableTaskListItems', () => {
    it('should enable markdown tasks and disable non-markdown tasks', () => {
      taskList.disableTaskListItems();
      taskList.enableTaskListItems();

      expect(document.querySelectorAll('.task-list-item input:enabled')).toHaveLength(1);
      expect(document.querySelectorAll('.task-list-item input:disabled')).toHaveLength(1);
    });
  });

  describe('enable', () => {
    it('should enable task list items and add change event listener', () => {
      const addEventListenerSpy = jest.spyOn(document, 'addEventListener');

      taskList.enable();

      expect(document.querySelectorAll('.task-list-item input:enabled')).toHaveLength(1);
      expect(document.querySelectorAll('.task-list-item input:disabled')).toHaveLength(1);

      expect(addEventListenerSpy).toHaveBeenCalledWith('change', taskList.updateHandler);
    });
  });

  describe('disable', () => {
    it('should disable task list items and remove change event listener', () => {
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');

      taskList.disable();

      expect(document.querySelectorAll('.task-list-item input:disabled')).toHaveLength(2);

      expect(removeEventListenerSpy).toHaveBeenCalledWith('change', taskList.updateHandler);
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
      const value = '* [x] markdown task';
      const endpoint = `${TEST_HOST}/test/update`;
      const dataType = options.dataType === 'incident' ? 'issue' : options.dataType;
      const patchData = {
        [dataType]: {
          [options.fieldName]: value,
          lock_version: options.lockVersion,
          update_task: {
            checked: true,
            line_source: '* [ ] markdown task',
            line_sourcepos: '1:4-1:4',
          },
        },
      };

      const container = document.querySelector(taskList.taskListContainerSelector);
      const checkbox = container.querySelector('.task-list-item-checkbox');
      checkbox.checked = true;

      const event = { target: checkbox };
      const update = taskList.update(event);

      expect(taskList.onUpdate).toHaveBeenCalled();

      return update.then(() => {
        expect(taskList.disableTaskListItems).toHaveBeenCalledWith(checkbox);
        expect(axios.patch).toHaveBeenCalledWith(endpoint, patchData);
        expect(taskList.enableTaskListItems).toHaveBeenCalledWith(checkbox);
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

    const container = document.querySelector(taskList.taskListContainerSelector);
    const checkbox = container.querySelector('.task-list-item-checkbox');
    checkbox.checked = true;

    const event = { target: checkbox };
    const update = taskList.update(event);

    expect(taskList.onUpdate).toHaveBeenCalled();

    return update.then(() => {
      expect(taskList.enableTaskListItems).toHaveBeenCalledWith(checkbox);
      expect(taskList.onError).toHaveBeenCalledWith(response.data);
    });
  });

  describe('multiple instances with same selector', () => {
    const selector = '.unique-task-list';
    let axiosMock;
    let patchRequestCount;

    // Simulates the pattern used in notes/store/legacy_notes/actions.js startTaskList()
    // where onSuccess creates a new TaskList instance to re-initialize after content changes
    const startTaskList = () =>
      new TaskList({
        selector,
        dataType: 'issue',
        fieldName: 'description',
        onSuccess: () => startTaskList(),
      });

    beforeEach(() => {
      patchRequestCount = 0;
      axiosMock = new AxiosMockAdapter(axios);
      axiosMock.onPatch(`${TEST_HOST}/update`).reply(() => {
        patchRequestCount += 1;
        return [HTTP_STATUS_OK, { lock_version: 1 }];
      });

      setHTMLFixture(`
        <div class="unique-task-list">
          <div class="js-task-list-container">
            <input type="checkbox" class="task-list-item-checkbox" data-checkbox-sourcepos="1:1-1:1">
            <textarea class="js-task-list-field" data-update-url="${TEST_HOST}/update"></textarea>
          </div>
        </div>
      `);

      startTaskList();
    });

    afterEach(() => {
      TaskList.instances.get(selector)?.disable();
      TaskList.instances.delete(selector);
      axiosMock.restore();
    });

    it('should not accumulate event handlers after multiple checkbox updates', async () => {
      const checkbox = document.querySelector('.task-list-item-checkbox');

      // Simulate user clicking checkbox 3 times
      // Each click: checkbox change -> PATCH request -> onSuccess -> new TaskList instance
      // Previous instance should be disabled before creating new one, causing only 3 requests
      checkbox.click();
      await axios.waitForAll();

      checkbox.click();
      await axios.waitForAll();

      checkbox.click();
      await axios.waitForAll();

      expect(patchRequestCount).toBe(3);
    });
  });
});
