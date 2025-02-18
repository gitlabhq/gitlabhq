import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import Draggable from 'vuedraggable';

import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { removeParams, updateHistory } from '~/lib/utils/url_utility';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import BoardColumn from '~/boards/components/board_column.vue';
import BoardContent from '~/boards/components/board_content.vue';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import updateBoardListMutation from '~/boards/graphql/board_list_update.mutation.graphql';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardDrawerWrapper from '~/boards/components/board_drawer_wrapper.vue';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import { DraggableItemTypes } from 'ee_else_ce/boards/constants';
import { DETAIL_VIEW_QUERY_PARAM_NAME } from '~/work_items/constants';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import {
  mockLists,
  mockListsById,
  updateBoardListResponse,
  boardListsQueryResponse,
} from '../mock_data';

jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

describe('BoardContent', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;
  let mockApollo;

  const updateListHandler = jest.fn().mockResolvedValue(updateBoardListResponse);
  const errorMessage = 'Failed to update list';
  const updateListHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessage));
  const mockUpdateCache = jest.fn();

  const createComponent = ({
    props = {},
    canAdminList = true,
    issuableType = 'issue',
    isIssueBoard = true,
    isEpicBoard = false,
    handler = updateListHandler,
    workItemDrawerEnabled = false,
  } = {}) => {
    mockApollo = createMockApollo([[updateBoardListMutation, handler]]);
    mockApollo.clients.defaultClient.cache.updateQuery = mockUpdateCache;
    const listQueryVariables = { isProject: true };

    mockApollo.clients.defaultClient.writeQuery({
      query: boardListsQuery,
      variables: listQueryVariables,
      data: boardListsQueryResponse.data,
    });

    wrapper = shallowMount(BoardContent, {
      apolloProvider: mockApollo,
      propsData: {
        boardId: 'gid://gitlab/Board/1',
        filterParams: {},
        isSwimlanesOn: false,
        boardLists: mockListsById,
        listQueryVariables,
        addColumnFormVisible: false,
        useWorkItemDrawer: workItemDrawerEnabled,
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
        fullPath: 'project-path',
        commentTemplatePaths: [],
      },
      stubs: {
        BoardContentSidebar: stubComponent(BoardContentSidebar, {
          template: '<div></div>',
        }),
        BoardDrawerWrapper: stubComponent(BoardDrawerWrapper, {
          template: `
            <div>
              <slot
                :active-issuable="{ listId: 1 }"
                :onDrawerClosed="() => {}"
                :onIssuableDeleted="() => {}"
                :onAttributeUpdated="() => {}"
                :onStateUpdated="() => {}"/>
            </div>`,
        }),
      },
    });
  };

  const findBoardColumns = () => wrapper.findAllComponents(BoardColumn);
  const findBoardAddNewColumn = () => wrapper.findComponent(BoardAddNewColumn);
  const findDraggable = () => wrapper.findComponent(Draggable);
  const findError = () => wrapper.findComponent(GlAlert);
  const findDrawerWrapper = () => wrapper.findComponent(BoardDrawerWrapper);
  const findWorkItemDrawer = () => wrapper.findComponent(WorkItemDrawer);

  const moveList = () => {
    const movableListsOrder = [mockLists[0].id, mockLists[1].id];

    findDraggable().vm.$emit('end', {
      item: { dataset: { listId: mockLists[0].id, draggableItemType: DraggableItemTypes.list } },
      newIndex: 1,
      to: {
        children: movableListsOrder.map((listId) => ({ dataset: { listId } })),
      },
    });
  };

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  describe('default', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders a BoardColumn component per list', () => {
      expect(wrapper.findAllComponents(BoardColumn)).toHaveLength(mockLists.length);
    });

    it('renders BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(true);
    });

    it('does not render board drawer wrapper', () => {
      expect(findDrawerWrapper().exists()).toBe(false);
    });

    it('does not display EpicsSwimlanes component', () => {
      expect(wrapper.findComponent(EpicsSwimlanes).exists()).toBe(false);
      expect(findError().exists()).toBe(false);
    });

    it('sets delay and delayOnTouchOnly attributes on board list', () => {
      const listEl = wrapper.findComponent({ ref: 'list' });

      expect(listEl.attributes('delay')).toBe('100');
      expect(listEl.attributes('delayontouchonly')).toBe('true');
    });

    it('does not show the "add column" form', () => {
      expect(findBoardAddNewColumn().exists()).toBe(false);
    });

    it('reorders lists', async () => {
      moveList();
      await waitForPromises();

      expect(updateListHandler).toHaveBeenCalled();
    });

    it('sets error on reorder lists failure', async () => {
      createComponent({ handler: updateListHandlerFailure });

      moveList();
      await waitForPromises();

      expect(cacheUpdates.setError).toHaveBeenCalled();
    });

    describe('when error is passed', () => {
      beforeEach(async () => {
        createComponent({ props: { error: 'Error' } });
        await waitForPromises();
      });

      it('displays error banner', () => {
        expect(findError().exists()).toBe(true);
      });

      it('dismisses error', async () => {
        findError().vm.$emit('dismiss');
        await nextTick();

        expect(cacheUpdates.setError).toHaveBeenCalledWith({ message: null, captureError: false });
      });
    });
  });

  describe('when issuableType is not issue', () => {
    beforeEach(() => {
      createComponent({ issuableType: 'foo', isIssueBoard: false });
    });

    it('does not render BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(false);
    });

    it('does not render board drawer wrapper', () => {
      expect(findDrawerWrapper().exists()).toBe(false);
    });
  });

  describe('can admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: true });
    });

    it('renders draggable component', () => {
      expect(findDraggable().exists()).toBe(true);
    });

    it('renders BoardAddNewColumnTrigger component', () => {
      expect(wrapper.findComponent(BoardAddNewColumnTrigger).exists()).toBe(true);
    });
  });

  describe('can not admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: false });
    });

    it('does not render draggable component', () => {
      expect(findDraggable().exists()).toBe(false);
    });
    it('does not BoardAddNewColumnTrigger component', () => {
      expect(wrapper.findComponent(BoardAddNewColumnTrigger).exists()).toBe(false);
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
        expect(column.classes()).toEqual(['!gl-hidden', 'sm:!gl-inline-block']);
      });
    });
  });

  describe('when work item drawer is enabled', () => {
    beforeEach(() => {
      createComponent({ workItemDrawerEnabled: true });
    });

    it('does not render board sidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(false);
    });

    it('renders board drawer wrapper', () => {
      expect(findDrawerWrapper().exists()).toBe(true);
    });

    it('updates Apollo cache when work item in the drawer is updated', () => {
      findWorkItemDrawer().vm.$emit('work-item-updated', { iid: '1' });

      expect(mockUpdateCache).toHaveBeenCalled();
    });
  });

  describe('when all columns cannot find active item', () => {
    beforeEach(() => {
      createComponent({ workItemDrawerEnabled: true });

      findBoardColumns().wrappers.forEach((column) => {
        column.vm.$emit('cannot-find-active-item');
      });
    });

    it('calls `updateHistory`', () => {
      expect(updateHistory).toHaveBeenCalled();
    });

    it('calls `removeParams`', () => {
      expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
    });
  });
});
