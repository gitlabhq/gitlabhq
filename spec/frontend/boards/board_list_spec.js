/* global List */
/* global ListIssue */

import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import eventHub from '~/boards/eventhub';
import waitForPromises from '../helpers/wait_for_promises';
import BoardList from '~/boards/components/board_list.vue';
import '~/boards/models/issue';
import '~/boards/models/list';
import { listObj, boardsMockInterceptor } from './mock_data';
import store from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';

const createComponent = ({ done, listIssueProps = {}, componentProps = {}, listProps = {} }) => {
  const el = document.createElement('div');

  document.body.appendChild(el);
  const mock = new MockAdapter(axios);
  mock.onAny().reply(boardsMockInterceptor);
  boardsStore.create();

  const BoardListComp = Vue.extend(BoardList);
  const list = new List({ ...listObj, ...listProps });
  const issue = new ListIssue({
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    labels: [],
    assignees: [],
    ...listIssueProps,
  });
  if (!Object.prototype.hasOwnProperty.call(listProps, 'issuesSize')) {
    list.issuesSize = 1;
  }
  list.issues.push(issue);

  const component = new BoardListComp({
    el,
    store,
    propsData: {
      disabled: false,
      list,
      issues: list.issues,
      loading: false,
      issueLinkBase: '/issues',
      rootPath: '/',
      ...componentProps,
    },
  }).$mount();

  Vue.nextTick(() => {
    done();
  });

  return { component, mock };
};

describe('Board list component', () => {
  let mock;
  let component;
  let getIssues;
  function generateIssues(compWrapper) {
    for (let i = 1; i < 20; i += 1) {
      const issue = { ...compWrapper.list.issues[0] };
      issue.id += i;
      compWrapper.list.issues.push(issue);
    }
  }

  describe('When Expanded', () => {
    beforeEach(done => {
      getIssues = jest.spyOn(List.prototype, 'getIssues').mockReturnValue(new Promise(() => {}));
      ({ mock, component } = createComponent({ done }));
    });

    afterEach(() => {
      mock.restore();
      component.$destroy();
    });

    it('loads first page of issues', () => {
      return waitForPromises().then(() => {
        expect(getIssues).toHaveBeenCalled();
      });
    });

    it('renders component', () => {
      expect(component.$el.classList.contains('board-list-component')).toBe(true);
    });

    it('renders loading icon', () => {
      component.loading = true;

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-list-loading')).not.toBeNull();
      });
    });

    it('renders issues', () => {
      expect(component.$el.querySelectorAll('.board-card').length).toBe(1);
    });

    it('sets data attribute with issue id', () => {
      expect(component.$el.querySelector('.board-card').getAttribute('data-issue-id')).toBe('1');
    });

    it('shows new issue form', () => {
      component.toggleForm();

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-new-issue-form')).not.toBeNull();

        expect(component.$el.querySelector('.is-smaller')).not.toBeNull();
      });
    });

    it('shows new issue form after eventhub event', () => {
      eventHub.$emit(`toggle-issue-form-${component.list.id}`);

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-new-issue-form')).not.toBeNull();

        expect(component.$el.querySelector('.is-smaller')).not.toBeNull();
      });
    });

    it('does not show new issue form for closed list', () => {
      component.list.type = 'closed';
      component.toggleForm();

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-new-issue-form')).toBeNull();
      });
    });

    it('shows count list item', () => {
      component.showCount = true;

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-list-count')).not.toBeNull();

        expect(component.$el.querySelector('.board-list-count').textContent.trim()).toBe(
          'Showing all issues',
        );
      });
    });

    it('sets data attribute with invalid id', () => {
      component.showCount = true;

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-list-count').getAttribute('data-issue-id')).toBe(
          '-1',
        );
      });
    });

    it('shows how many more issues to load', () => {
      component.showCount = true;
      component.list.issuesSize = 20;

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-list-count').textContent.trim()).toBe(
          'Showing 1 of 20 issues',
        );
      });
    });

    it('loads more issues after scrolling', () => {
      jest.spyOn(component.list, 'nextPage').mockImplementation(() => {});
      generateIssues(component);
      component.$refs.list.dispatchEvent(new Event('scroll'));

      return waitForPromises().then(() => {
        expect(component.list.nextPage).toHaveBeenCalled();
      });
    });

    it('does not load issues if already loading', () => {
      component.list.nextPage = jest
        .spyOn(component.list, 'nextPage')
        .mockReturnValue(new Promise(() => {}));

      component.onScroll();
      component.onScroll();

      return waitForPromises().then(() => {
        expect(component.list.nextPage).toHaveBeenCalledTimes(1);
      });
    });

    it('shows loading more spinner', () => {
      component.showCount = true;
      component.list.loadingMore = true;

      return Vue.nextTick().then(() => {
        expect(component.$el.querySelector('.board-list-count .gl-spinner')).not.toBeNull();
      });
    });
  });

  describe('When Collapsed', () => {
    beforeEach(done => {
      getIssues = jest.spyOn(List.prototype, 'getIssues').mockReturnValue(new Promise(() => {}));
      ({ mock, component } = createComponent({
        done,
        listProps: { type: 'closed', collapsed: true, issuesSize: 50 },
      }));
      generateIssues(component);
      component.scrollHeight = jest.spyOn(component, 'scrollHeight').mockReturnValue(0);
    });

    afterEach(() => {
      mock.restore();
      component.$destroy();
    });

    it('does not load all issues', () => {
      return waitForPromises().then(() => {
        // Initial getIssues from list constructor
        expect(getIssues).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('max issue count warning', () => {
    beforeEach(done => {
      ({ mock, component } = createComponent({
        done,
        listProps: { type: 'closed', collapsed: true, issuesSize: 50 },
      }));
    });

    afterEach(() => {
      mock.restore();
      component.$destroy();
    });

    describe('when issue count exceeds max issue count', () => {
      it('sets background to bg-danger-100', () => {
        component.list.issuesSize = 4;
        component.list.maxIssueCount = 3;

        return Vue.nextTick().then(() => {
          expect(component.$el.querySelector('.bg-danger-100')).not.toBeNull();
        });
      });
    });

    describe('when list issue count does NOT exceed list max issue count', () => {
      it('does not sets background to bg-danger-100', () => {
        component.list.issuesSize = 2;
        component.list.maxIssueCount = 3;

        return Vue.nextTick().then(() => {
          expect(component.$el.querySelector('.bg-danger-100')).toBeNull();
        });
      });
    });

    describe('when list max issue count is 0', () => {
      it('does not sets background to bg-danger-100', () => {
        component.list.maxIssueCount = 0;

        return Vue.nextTick().then(() => {
          expect(component.$el.querySelector('.bg-danger-100')).toBeNull();
        });
      });
    });
  });
});
