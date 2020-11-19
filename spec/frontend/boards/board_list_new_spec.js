/* global List */
/* global ListIssue */

import Vuex from 'vuex';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import { createLocalVue, mount } from '@vue/test-utils';
import eventHub from '~/boards/eventhub';
import BoardList from '~/boards/components/board_list_new.vue';
import BoardCard from '~/boards/components/board_card.vue';
import '~/boards/models/issue';
import '~/boards/models/list';
import { listObj, mockIssuesByListId, issues } from './mock_data';
import defaultState from '~/boards/stores/state';

const localVue = createLocalVue();
localVue.use(Vuex);

const actions = {
  fetchIssuesForList: jest.fn(),
};

const createStore = (state = defaultState) => {
  return new Vuex.Store({
    state,
    actions,
  });
};

const createComponent = ({
  listIssueProps = {},
  componentProps = {},
  listProps = {},
  state = {},
} = {}) => {
  const store = createStore({
    issuesByListId: mockIssuesByListId,
    issues,
    pageInfoByListId: {
      'gid://gitlab/List/1': { hasNextPage: true },
      'gid://gitlab/List/2': {},
    },
    listsFlags: {
      'gid://gitlab/List/1': {},
      'gid://gitlab/List/2': {},
    },
    ...state,
  });

  const list = new List({
    ...listObj,
    id: 'gid://gitlab/List/1',
    ...listProps,
    doNotFetchIssues: true,
  });
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

  const component = mount(BoardList, {
    localVue,
    propsData: {
      disabled: false,
      list,
      issues: [issue],
      ...componentProps,
    },
    store,
    provide: {
      groupId: null,
      rootPath: '/',
      weightFeatureAvailable: false,
      boardWeight: null,
    },
  });

  return component;
};

describe('Board list component', () => {
  let wrapper;
  useFakeRequestAnimationFrame();

  describe('When Expanded', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders component', () => {
      expect(wrapper.find('.board-list-component').exists()).toBe(true);
    });

    it('renders loading icon', () => {
      wrapper = createComponent({
        state: { listsFlags: { 'gid://gitlab/List/1': { isLoading: true } } },
      });

      expect(wrapper.find('[data-testid="board_list_loading"').exists()).toBe(true);
    });

    it('renders issues', () => {
      expect(wrapper.findAll(BoardCard).length).toBe(1);
    });

    it('sets data attribute with issue id', () => {
      expect(wrapper.find('.board-card').attributes('data-issue-id')).toBe('1');
    });

    it('shows new issue form', async () => {
      wrapper.vm.toggleForm();

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-new-issue-form').exists()).toBe(true);
    });

    it('shows new issue form after eventhub event', async () => {
      eventHub.$emit(`toggle-issue-form-${wrapper.vm.list.id}`);

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-new-issue-form').exists()).toBe(true);
    });

    it('does not show new issue form for closed list', () => {
      wrapper.setProps({ list: { type: 'closed' } });
      wrapper.vm.toggleForm();

      expect(wrapper.find('.board-new-issue-form').exists()).toBe(false);
    });

    it('shows count list item', async () => {
      wrapper.vm.showCount = true;

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count').exists()).toBe(true);

      expect(wrapper.find('.board-list-count').text()).toBe('Showing all issues');
    });

    it('sets data attribute with invalid id', async () => {
      wrapper.vm.showCount = true;

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count').attributes('data-issue-id')).toBe('-1');
    });

    it('shows how many more issues to load', async () => {
      wrapper.vm.showCount = true;
      wrapper.setProps({ list: { issuesSize: 20 } });

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count').text()).toBe('Showing 1 of 20 issues');
    });
  });

  describe('load more issues', () => {
    beforeEach(() => {
      wrapper = createComponent({
        listProps: { issuesSize: 25 },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('loads more issues after scrolling', () => {
      wrapper.vm.$refs.list.dispatchEvent(new Event('scroll'));

      expect(actions.fetchIssuesForList).toHaveBeenCalled();
    });

    it('does not load issues if already loading', () => {
      wrapper.vm.$refs.list.dispatchEvent(new Event('scroll'));
      wrapper.vm.$refs.list.dispatchEvent(new Event('scroll'));

      expect(actions.fetchIssuesForList).toHaveBeenCalledTimes(1);
    });

    it('shows loading more spinner', async () => {
      wrapper.vm.showCount = true;
      wrapper.vm.list.loadingMore = true;

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count .gl-spinner').exists()).toBe(true);
    });
  });

  describe('max issue count warning', () => {
    beforeEach(() => {
      wrapper = createComponent({
        listProps: { issuesSize: 50 },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('when issue count exceeds max issue count', () => {
      it('sets background to bg-danger-100', async () => {
        wrapper.setProps({ list: { issuesSize: 4, maxIssueCount: 3 } });

        await wrapper.vm.$nextTick();
        expect(wrapper.find('.bg-danger-100').exists()).toBe(true);
      });
    });

    describe('when list issue count does NOT exceed list max issue count', () => {
      it('does not sets background to bg-danger-100', () => {
        wrapper.setProps({ list: { issuesSize: 2, maxIssueCount: 3 } });

        expect(wrapper.find('.bg-danger-100').exists()).toBe(false);
      });
    });

    describe('when list max issue count is 0', () => {
      it('does not sets background to bg-danger-100', () => {
        wrapper.setProps({ list: { maxIssueCount: 0 } });

        expect(wrapper.find('.bg-danger-100').exists()).toBe(false);
      });
    });
  });
});
