import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import ProjectSelect from '~/boards/components/project_select.vue';
import eventHub from '~/boards/eventhub';

import { mockList, mockGroupProjects, mockIssue, mockIssue2 } from '../mock_data';

Vue.use(Vuex);

const addListNewIssuesSpy = jest.fn().mockResolvedValue();
const mockActions = { addListNewIssue: addListNewIssuesSpy };

const createComponent = ({
  state = { selectedProject: mockGroupProjects[0] },
  actions = mockActions,
  getters = { getBoardItemsByList: () => () => [] },
  isGroupBoard = true,
} = {}) =>
  shallowMount(BoardNewIssue, {
    store: new Vuex.Store({
      state,
      actions,
      getters,
    }),
    propsData: {
      list: mockList,
    },
    provide: {
      groupId: 1,
      fullPath: mockGroupProjects[0].fullPath,
      weightFeatureAvailable: false,
      boardWeight: null,
      isGroupBoard,
    },
    stubs: {
      BoardNewItem,
    },
  });

describe('Issue boards new issue form', () => {
  let wrapper;

  const findBoardNewItem = () => wrapper.findComponent(BoardNewItem);

  beforeEach(async () => {
    wrapper = createComponent();

    await nextTick();
  });

  it('renders board-new-item component', () => {
    const boardNewItem = findBoardNewItem();
    expect(boardNewItem.exists()).toBe(true);
    expect(boardNewItem.props()).toEqual({
      list: mockList,
      formEventPrefix: 'toggle-issue-form-',
      submitButtonTitle: 'Create issue',
      disableSubmit: false,
    });
  });

  it('calls addListNewIssue action when `board-new-item` emits form-submit event', async () => {
    findBoardNewItem().vm.$emit('form-submit', { title: 'Foo' });

    await nextTick();
    expect(addListNewIssuesSpy).toHaveBeenCalledWith(expect.any(Object), {
      list: mockList,
      issueInput: {
        title: 'Foo',
        labelIds: [],
        assigneeIds: [],
        milestoneId: undefined,
        projectPath: mockGroupProjects[0].fullPath,
        moveAfterId: undefined,
      },
    });
  });

  describe('when list has an existing issues', () => {
    beforeEach(() => {
      wrapper = createComponent({
        getters: {
          getBoardItemsByList: () => () => [mockIssue, mockIssue2],
        },
        isGroupBoard: true,
      });
    });

    it('uses the first issue ID as moveAfterId', async () => {
      findBoardNewItem().vm.$emit('form-submit', { title: 'Foo' });

      await nextTick();
      expect(addListNewIssuesSpy).toHaveBeenCalledWith(expect.any(Object), {
        list: mockList,
        issueInput: {
          title: 'Foo',
          labelIds: [],
          assigneeIds: [],
          milestoneId: undefined,
          projectPath: mockGroupProjects[0].fullPath,
          moveAfterId: mockIssue.id,
        },
      });
    });
  });

  it('emits event `toggle-issue-form` with current list Id suffix on eventHub when `board-new-item` emits form-cancel event', async () => {
    jest.spyOn(eventHub, '$emit').mockImplementation();
    findBoardNewItem().vm.$emit('form-cancel');

    await nextTick();
    expect(eventHub.$emit).toHaveBeenCalledWith(`toggle-issue-form-${mockList.id}`);
  });

  describe('when in group issue board', () => {
    it('renders project-select component within board-new-item component', () => {
      const projectSelect = findBoardNewItem().findComponent(ProjectSelect);

      expect(projectSelect.exists()).toBe(true);
      expect(projectSelect.props('list')).toEqual(mockList);
    });
  });

  describe('when in project issue board', () => {
    beforeEach(() => {
      wrapper = createComponent({
        isGroupBoard: false,
      });
    });

    it('does not render project-select component within board-new-item component', () => {
      const projectSelect = findBoardNewItem().findComponent(ProjectSelect);

      expect(projectSelect.exists()).toBe(false);
    });
  });
});
