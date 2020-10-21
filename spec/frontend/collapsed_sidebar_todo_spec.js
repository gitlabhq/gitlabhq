/* eslint-disable no-new */
import { clone } from 'lodash';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import Sidebar from '~/right_sidebar';
import waitForPromises from './helpers/wait_for_promises';

describe('Issuable right sidebar collapsed todo toggle', () => {
  const fixtureName = 'issues/open-issue.html';
  const jsonFixtureName = 'todos/todos.json';
  let mock;

  preloadFixtures(fixtureName);
  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    const todoData = getJSONFixture(jsonFixtureName);
    new Sidebar();
    loadFixtures(fixtureName);

    document.querySelector('.js-right-sidebar').classList.toggle('right-sidebar-expanded');
    document.querySelector('.js-right-sidebar').classList.toggle('right-sidebar-collapsed');

    mock = new MockAdapter(axios);

    mock.onPost(`${TEST_HOST}/frontend-fixtures/issues-project/todos`).reply(() => {
      const response = clone(todoData);

      return [200, response];
    });

    mock.onDelete(/(.*)\/dashboard\/todos\/\d+$/).reply(() => {
      const response = clone(todoData);
      delete response.delete_path;

      return [200, response];
    });
  });

  afterEach(() => {
    mock.restore();
  });

  it('shows add todo button', () => {
    expect(document.querySelector('.js-issuable-todo.sidebar-collapsed-icon')).not.toBeNull();

    expect(
      document
        .querySelector('.js-issuable-todo.sidebar-collapsed-icon svg')
        .getAttribute('data-testid'),
    ).toBe('todo-add-icon');

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
    ).toBeNull();
  });

  it('sets default tooltip title', () => {
    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('title'),
    ).toBe('Add a to do');
  });

  it('toggle todo state', done => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setImmediate(() => {
      expect(
        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
      ).not.toBeNull();

      expect(
        document
          .querySelector('.js-issuable-todo.sidebar-collapsed-icon svg.todo-undone')
          .getAttribute('data-testid'),
      ).toBe('todo-done-icon');

      done();
    });
  });

  it('toggle todo state of expanded todo toggle', done => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setImmediate(() => {
      expect(
        document.querySelector('.issuable-sidebar-header .js-issuable-todo').textContent.trim(),
      ).toBe('Mark as done');

      done();
    });
  });

  it('toggles todo button tooltip', done => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setImmediate(() => {
      expect(
        document
          .querySelector('.js-issuable-todo.sidebar-collapsed-icon')
          .getAttribute('data-original-title'),
      ).toBe('Mark as done');

      done();
    });
  });

  it('marks todo as done', done => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    waitForPromises()
      .then(() => {
        expect(
          document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
        ).not.toBeNull();

        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();
      })
      .then(waitForPromises)
      .then(() => {
        expect(
          document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
        ).toBeNull();

        expect(
          document.querySelector('.issuable-sidebar-header .js-issuable-todo').textContent.trim(),
        ).toBe('Add a to do');
      })
      .then(done)
      .catch(done.fail);
  });

  it('updates aria-label to Mark as done', done => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setImmediate(() => {
      expect(
        document
          .querySelector('.js-issuable-todo.sidebar-collapsed-icon')
          .getAttribute('aria-label'),
      ).toBe('Mark as done');

      done();
    });
  });

  it('updates aria-label to add todo', done => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    waitForPromises()
      .then(() => {
        expect(
          document
            .querySelector('.js-issuable-todo.sidebar-collapsed-icon')
            .getAttribute('aria-label'),
        ).toBe('Mark as done');

        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();
      })
      .then(waitForPromises)
      .then(() => {
        expect(
          document
            .querySelector('.js-issuable-todo.sidebar-collapsed-icon')
            .getAttribute('aria-label'),
        ).toBe('Add a to do');
      })
      .then(done)
      .catch(done.fail);
  });
});
