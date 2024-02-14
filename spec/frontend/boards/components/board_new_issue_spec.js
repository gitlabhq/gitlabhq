import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import ProjectSelect from '~/boards/components/project_select.vue';
import groupBoardQuery from '~/boards/graphql/group_board.query.graphql';
import projectBoardQuery from '~/boards/graphql/project_board.query.graphql';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';

import {
  mockList,
  mockGroupProjects,
  mockProjectBoardResponse,
  mockGroupBoardResponse,
} from '../mock_data';

Vue.use(VueApollo);

const projectBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectBoardResponse);
const groupBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupBoardResponse);

const mockApollo = createMockApollo([
  [projectBoardQuery, projectBoardQueryHandlerSuccess],
  [groupBoardQuery, groupBoardQueryHandlerSuccess],
]);

const createComponent = ({
  isGroupBoard = true,
  data = { selectedProject: mockGroupProjects[0] },
  provide = {},
} = {}) =>
  shallowMount(BoardNewIssue, {
    apolloProvider: mockApollo,
    propsData: {
      list: mockList,
      boardId: 'gid://gitlab/Board/1',
    },
    data: () => data,
    provide: {
      groupId: 1,
      fullPath: mockGroupProjects[0].fullPath,
      weightFeatureAvailable: false,
      boardWeight: null,
      isGroupBoard,
      boardType: 'group',
      isEpicBoard: false,
      ...provide,
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

  it.each`
    boardType            | queryHandler                       | notCalledHandler
    ${WORKSPACE_GROUP}   | ${groupBoardQueryHandlerSuccess}   | ${projectBoardQueryHandlerSuccess}
    ${WORKSPACE_PROJECT} | ${projectBoardQueryHandlerSuccess} | ${groupBoardQueryHandlerSuccess}
  `(
    'fetches $boardType board and emits addNewIssue event',
    async ({ boardType, queryHandler, notCalledHandler }) => {
      wrapper = createComponent({
        provide: {
          boardType,
          isProjectBoard: boardType === WORKSPACE_PROJECT,
          isGroupBoard: boardType === WORKSPACE_GROUP,
        },
      });

      await nextTick();
      findBoardNewItem().vm.$emit('form-submit', { title: 'Foo' });

      await nextTick();

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
      expect(wrapper.emitted('addNewIssue')[0][0]).toMatchObject({ title: 'Foo' });
    },
  );

  it('renders board-new-item component', () => {
    const boardNewItem = findBoardNewItem();
    expect(boardNewItem.exists()).toBe(true);
    expect(boardNewItem.props()).toEqual({
      list: mockList,
      submitButtonTitle: 'Create issue',
      disableSubmit: false,
    });
  });

  it('emits event `toggleNewForm` when `board-new-item` emits form-cancel event', async () => {
    findBoardNewItem().vm.$emit('form-cancel');

    await nextTick();
    expect(wrapper.emitted('toggleNewForm')).toHaveLength(1);
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
