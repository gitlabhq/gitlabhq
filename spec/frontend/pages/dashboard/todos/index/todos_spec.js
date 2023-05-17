import MockAdapter from 'axios-mock-adapter';
import htmlTodos from 'test_fixtures/todos/todos.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { addDelimiter } from '~/lib/utils/text_utility';
import Todos from '~/pages/dashboard/todos/index/todos';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrl'),
}));

const TEST_COUNT_BIG = 2000;
const TEST_DONE_COUNT_BIG = 7300;

describe('Todos', () => {
  let mock;

  beforeEach(() => {
    setHTMLFixture(htmlTodos);
    mock = new MockAdapter(axios);

    return new Todos();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('on done todo click', () => {
    let onToggleSpy;

    beforeEach(() => {
      const el = document.querySelector('.js-done-todo');
      const path = el.dataset.href;

      // Arrange
      mock
        .onDelete(path)
        .replyOnce(HTTP_STATUS_OK, { count: TEST_COUNT_BIG, done_count: TEST_DONE_COUNT_BIG });
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
