import MockAdapter from 'axios-mock-adapter';
import { loadHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import { addDelimiter } from '~/lib/utils/text_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import Todos from '~/pages/dashboard/todos/index/todos';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrl'),
}));

const TEST_COUNT_BIG = 2000;
const TEST_DONE_COUNT_BIG = 7300;

describe('Todos', () => {
  let todoItem;
  let mock;

  beforeEach(() => {
    loadHTMLFixture('todos/todos.html');
    todoItem = document.querySelector('.todos-list .todo');
    mock = new MockAdapter(axios);

    return new Todos();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('goToTodoUrl', () => {
    it('opens the todo url', () => {
      const todoLink = todoItem.dataset.url;

      let expectedUrl = null;
      visitUrl.mockImplementation((url) => {
        expectedUrl = url;
      });

      todoItem.click();

      expect(expectedUrl).toEqual(todoLink);
    });

    describe('meta click', () => {
      let windowOpenSpy;
      let metakeyEvent;

      beforeEach(() => {
        metakeyEvent = new MouseEvent('click', { ctrlKey: true });
        windowOpenSpy = jest.spyOn(window, 'open').mockImplementation(() => {});
      });

      it('opens the todo url in another tab', () => {
        const todoLink = todoItem.dataset.url;

        document.querySelectorAll('.todos-list .todo').forEach((el) => {
          el.dispatchEvent(metakeyEvent);
        });

        expect(visitUrl).not.toHaveBeenCalled();
        expect(windowOpenSpy).toHaveBeenCalledWith(todoLink, '_blank');
      });

      it('run native funcionality when avatar is clicked', () => {
        document.querySelectorAll('.todos-list a').forEach((el) => {
          el.addEventListener('click', (e) => e.preventDefault());
        });
        document.querySelectorAll('.todos-list img').forEach((el) => {
          el.dispatchEvent(metakeyEvent);
        });

        expect(visitUrl).not.toHaveBeenCalled();
        expect(windowOpenSpy).not.toHaveBeenCalled();
      });
    });

    describe('on done todo click', () => {
      let onToggleSpy;

      beforeEach(() => {
        const el = document.querySelector('.js-done-todo');
        const path = el.dataset.href;

        // Arrange
        mock
          .onDelete(path)
          .replyOnce(200, { count: TEST_COUNT_BIG, done_count: TEST_DONE_COUNT_BIG });
        onToggleSpy = jest.fn();
        document.addEventListener('todo:toggle', onToggleSpy);

        // Act
        el.click();

        // Wait for axios and HTML to udpate
        return waitForPromises();
      });

      it('dispatches todo:toggle', () => {
        expect(onToggleSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: {
              count: TEST_COUNT_BIG,
            },
          }),
        );
      });

      it('updates pending text', () => {
        expect(document.querySelector('.js-todos-pending .js-todos-badge').innerHTML).toEqual(
          addDelimiter(TEST_COUNT_BIG),
        );
      });

      it('updates done text', () => {
        expect(document.querySelector('.js-todos-done .js-todos-badge').innerHTML).toEqual(
          addDelimiter(TEST_DONE_COUNT_BIG),
        );
      });
    });
  });
});
