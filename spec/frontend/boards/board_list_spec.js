import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import BoardCard from '~/boards/components/board_card.vue';
import BoardList from '~/boards/components/board_list.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import eventHub from '~/boards/eventhub';
import defaultState from '~/boards/stores/state';
import { mockList, mockIssuesByListId, issues, mockIssues } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const actions = {
  fetchItemsForList: jest.fn(),
};

const createStore = (state = defaultState) => {
  return new Vuex.Store({
    state,
    actions,
    getters: {
      isGroupBoard: () => false,
      isProjectBoard: () => true,
      isEpicBoard: () => false,
    },
  });
};

const createComponent = ({
  listIssueProps = {},
  componentProps = {},
  listProps = {},
  state = {},
} = {}) => {
  const store = createStore({
    boardItemsByListId: mockIssuesByListId,
    boardItems: issues,
    pageInfoByListId: {
      'gid://gitlab/List/1': { hasNextPage: true },
      'gid://gitlab/List/2': {},
    },
    listsFlags: {
      'gid://gitlab/List/1': {},
      'gid://gitlab/List/2': {},
    },
    selectedBoardItems: [],
    ...state,
  });

  const list = {
    ...mockList,
    ...listProps,
  };
  const issue = {
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    labels: [],
    assignees: [],
    ...listIssueProps,
  };
  if (!Object.prototype.hasOwnProperty.call(listProps, 'issuesCount')) {
    list.issuesCount = 1;
  }

  const component = shallowMount(BoardList, {
    localVue,
    propsData: {
      disabled: false,
      list,
      boardItems: [issue],
      canAdminList: true,
      ...componentProps,
    },
    store,
    provide: {
      groupId: null,
      rootPath: '/',
      weightFeatureAvailable: false,
      boardWeight: null,
    },
    stubs: {
      BoardCard,
      BoardNewIssue,
    },
  });

  return component;
};

describe('Board list component', () => {
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findIssueCountLoadingIcon = () => wrapper.find('[data-testid="count-loading-icon"]');

  useFakeRequestAnimationFrame();

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('When Expanded', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders component', () => {
      expect(wrapper.find('.board-list-component').exists()).toBe(true);
    });

    it('renders loading icon', () => {
      wrapper = createComponent({
        state: { listsFlags: { 'gid://gitlab/List/1': { isLoading: true } } },
      });

      expect(findByTestId('board_list_loading').exists()).toBe(true);
    });

    it('renders issues', () => {
      expect(wrapper.findAll(BoardCard).length).toBe(1);
    });

    it('sets data attribute with issue id', () => {
      expect(wrapper.find('.board-card').attributes('data-item-id')).toBe('1');
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
      wrapper.setProps({ list: { issuesCount: 20 } });

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count').text()).toBe('Showing 1 of 20 issues');
    });
  });

  describe('load more issues', () => {
    beforeEach(() => {
      wrapper = createComponent({
        listProps: { issuesCount: 25 },
      });
    });

    it('loads more issues after scrolling', () => {
      wrapper.vm.listRef.dispatchEvent(new Event('scroll'));

      expect(actions.fetchItemsForList).toHaveBeenCalled();
    });

    it('does not load issues if already loading', () => {
      wrapper = createComponent({
        state: { listsFlags: { 'gid://gitlab/List/1': { isLoadingMore: true } } },
      });
      wrapper.vm.listRef.dispatchEvent(new Event('scroll'));

      expect(actions.fetchItemsForList).not.toHaveBeenCalled();
    });

    it('shows loading more spinner', async () => {
      wrapper = createComponent({
        state: { listsFlags: { 'gid://gitlab/List/1': { isLoadingMore: true } } },
      });
      wrapper.vm.showCount = true;

      await wrapper.vm.$nextTick();

      expect(findIssueCountLoadingIcon().exists()).toBe(true);
    });
  });

  describe('max issue count warning', () => {
    beforeEach(() => {
      wrapper = createComponent({
        listProps: { issuesCount: 50 },
      });
    });

    describe('when issue count exceeds max issue count', () => {
      it('sets background to bg-danger-100', async () => {
        wrapper.setProps({ list: { issuesCount: 4, maxIssueCount: 3 } });

        await wrapper.vm.$nextTick();
        expect(wrapper.find('.bg-danger-100').exists()).toBe(true);
      });
    });

    describe('when list issue count does NOT exceed list max issue count', () => {
      it('does not sets background to bg-danger-100', () => {
        wrapper.setProps({ list: { issuesCount: 2, maxIssueCount: 3 } });

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

  describe('drag & drop issue', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('handleDragOnStart', () => {
      it('adds a class `is-dragging` to document body', () => {
        expect(document.body.classList.contains('is-dragging')).toBe(false);

        findByTestId('tree-root-wrapper').vm.$emit('start');

        expect(document.body.classList.contains('is-dragging')).toBe(true);
      });
    });

    describe('handleDragOnEnd', () => {
      it('removes class `is-dragging` from document body', () => {
        jest.spyOn(wrapper.vm, 'moveItem').mockImplementation(() => {});
        document.body.classList.add('is-dragging');

        findByTestId('tree-root-wrapper').vm.$emit('end', {
          oldIndex: 1,
          newIndex: 0,
          item: {
            dataset: {
              itemId: mockIssues[0].id,
              itemIid: mockIssues[0].iid,
              itemPath: mockIssues[0].referencePath,
            },
          },
          to: { children: [], dataset: { listId: 'gid://gitlab/List/1' } },
          from: { dataset: { listId: 'gid://gitlab/List/2' } },
        });

        expect(document.body.classList.contains('is-dragging')).toBe(false);
      });
    });
  });
});
