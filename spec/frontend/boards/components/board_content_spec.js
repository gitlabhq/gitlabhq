import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import Draggable from 'vuedraggable';
import Vuex from 'vuex';
import eventHub from '~/boards/eventhub';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import getters from 'ee_else_ce/boards/stores/getters';
import BoardColumn from '~/boards/components/board_column.vue';
import BoardContent from '~/boards/components/board_content.vue';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import updateBoardListMutation from '~/boards/graphql/board_list_update.mutation.graphql';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import { DraggableItemTypes } from 'ee_else_ce/boards/constants';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import {
  mockLists,
  mockListsById,
  updateBoardListResponse,
  boardListsQueryResponse,
} from '../mock_data';

Vue.use(VueApollo);
Vue.use(Vuex);

const actions = {
  moveList: jest.fn(),
};

describe('BoardContent', () => {
  let wrapper;
  let mockApollo;

  const updateListHandler = jest.fn().mockResolvedValue(updateBoardListResponse);

  const defaultState = {
    isShowingEpicsSwimlanes: false,
    boardLists: mockListsById,
    error: undefined,
    issuableType: 'issue',
  };

  const createStore = (state = defaultState) => {
    return new Vuex.Store({
      actions,
      getters,
      state,
    });
  };

  const createComponent = ({
    state,
    props = {},
    canAdminList = true,
    isApolloBoard = false,
    issuableType = 'issue',
    isIssueBoard = true,
    isEpicBoard = false,
  } = {}) => {
    mockApollo = createMockApollo([[updateBoardListMutation, updateListHandler]]);
    const listQueryVariables = { isProject: true };

    mockApollo.clients.defaultClient.writeQuery({
      query: boardListsQuery,
      variables: listQueryVariables,
      data: boardListsQueryResponse.data,
    });

    const store = createStore({
      ...defaultState,
      ...state,
    });
    wrapper = shallowMount(BoardContent, {
      apolloProvider: mockApollo,
      propsData: {
        boardId: 'gid://gitlab/Board/1',
        filterParams: {},
        isSwimlanesOn: false,
        boardListsApollo: mockListsById,
        listQueryVariables,
        addColumnFormVisible: false,
        ...props,
      },
      provide: {
        boardType: 'project',
        canAdminList,
        issuableType,
        isIssueBoard,
        isEpicBoard,
        isGroupBoard: true,
        disabled: false,
        isApolloBoard,
      },
      store,
      stubs: {
        BoardContentSidebar: stubComponent(BoardContentSidebar, {
          template: '<div></div>',
        }),
      },
    });
  };

  const findBoardColumns = () => wrapper.findAllComponents(BoardColumn);
  const findBoardAddNewColumn = () => wrapper.findComponent(BoardAddNewColumn);
  const findDraggable = () => wrapper.findComponent(Draggable);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a BoardColumn component per list', () => {
      expect(wrapper.findAllComponents(BoardColumn)).toHaveLength(mockLists.length);
    });

    it('renders BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(true);
    });

    it('does not display EpicsSwimlanes component', () => {
      expect(wrapper.findComponent(EpicsSwimlanes).exists()).toBe(false);
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });

    it('sets delay and delayOnTouchOnly attributes on board list', () => {
      const listEl = wrapper.findComponent({ ref: 'list' });

      expect(listEl.attributes('delay')).toBe('100');
      expect(listEl.attributes('delayontouchonly')).toBe('true');
    });

    it('does not show the "add column" form', () => {
      expect(findBoardAddNewColumn().exists()).toBe(false);
    });
  });

  describe('when issuableType is not issue', () => {
    beforeEach(() => {
      createComponent({ issuableType: 'foo', isIssueBoard: false });
    });

    it('does not render BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(false);
    });
  });

  describe('can admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: true });
    });

    it('renders draggable component', () => {
      expect(findDraggable().exists()).toBe(true);
    });
  });

  describe('can not admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: false });
    });

    it('does not render draggable component', () => {
      expect(findDraggable().exists()).toBe(false);
    });
  });

  describe('when Apollo boards FF is on', () => {
    beforeEach(async () => {
      createComponent({ isApolloBoard: true });
      await waitForPromises();
    });

    it('renders a BoardColumn component per list', () => {
      expect(wrapper.findAllComponents(BoardColumn)).toHaveLength(mockLists.length);
    });

    it('renders BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(true);
    });

    it('refetches lists when updateBoard event is received', async () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});

      createComponent({ isApolloBoard: true });
      await waitForPromises();

      expect(eventHub.$on).toHaveBeenCalledWith('updateBoard', wrapper.vm.refetchLists);
    });

    it('reorders lists', async () => {
      const movableListsOrder = [mockLists[0].id, mockLists[1].id];

      findDraggable().vm.$emit('end', {
        item: { dataset: { listId: mockLists[0].id, draggableItemType: DraggableItemTypes.list } },
        newIndex: 1,
        to: {
          children: movableListsOrder.map((listId) => ({ dataset: { listId } })),
        },
      });
      await waitForPromises();

      expect(updateListHandler).toHaveBeenCalled();
    });
  });

  describe('when "add column" form is visible', () => {
    beforeEach(() => {
      createComponent({ props: { addColumnFormVisible: true } });
    });

    it('shows the "add column" form', () => {
      expect(findBoardAddNewColumn().exists()).toBe(true);
    });

    it('hides other columns on mobile viewports', () => {
      findBoardColumns().wrappers.forEach((column) => {
        expect(column.classes()).toEqual(['gl-display-none!', 'gl-sm-display-inline-block!']);
      });
    });
  });
});
