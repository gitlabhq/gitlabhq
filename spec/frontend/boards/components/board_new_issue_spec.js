import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import ProjectSelect from '~/boards/components/project_select.vue';
import eventHub from '~/boards/eventhub';

import { mockList, mockGroupProjects } from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

const addListNewIssuesSpy = jest.fn().mockResolvedValue();
const mockActions = { addListNewIssue: addListNewIssuesSpy };

const createComponent = ({
  state = { selectedProject: mockGroupProjects[0], fullPath: mockGroupProjects[0].fullPath },
  actions = mockActions,
  getters = { isGroupBoard: () => true, isProjectBoard: () => false },
} = {}) =>
  shallowMount(BoardNewIssue, {
    localVue,
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
      weightFeatureAvailable: false,
      boardWeight: null,
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

    await wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
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

    await wrapper.vm.$nextTick();
    expect(addListNewIssuesSpy).toHaveBeenCalledWith(expect.any(Object), {
      list: mockList,
      issueInput: {
        title: 'Foo',
        labelIds: [],
        assigneeIds: [],
        milestoneId: undefined,
        projectPath: mockGroupProjects[0].fullPath,
      },
    });
  });

  it('emits event `toggle-issue-form` with current list Id suffix on eventHub when `board-new-item` emits form-cancel event', async () => {
    jest.spyOn(eventHub, '$emit').mockImplementation();
    findBoardNewItem().vm.$emit('form-cancel');

    await wrapper.vm.$nextTick();
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
        getters: { isGroupBoard: () => false, isProjectBoard: () => true },
      });
    });

    it('does not render project-select component within board-new-item component', () => {
      const projectSelect = findBoardNewItem().findComponent(ProjectSelect);

      expect(projectSelect.exists()).toBe(false);
    });
  });
});
