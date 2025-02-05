<script>
import { GlAlert } from '@gitlab/ui';
import { sortBy } from 'lodash';
import produce from 'immer';
import Draggable from 'vuedraggable';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import { s__ } from '~/locale';
import { removeParams, updateHistory } from '~/lib/utils/url_utility';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import { mapWorkItemWidgetsToIssuableFields } from '~/issues/list/utils';
import {
  DraggableItemTypes,
  flashAnimationDuration,
  listsQuery,
  updateListQueries,
  ListType,
  listIssuablesQueries,
  DEFAULT_BOARD_LIST_ITEMS_SIZE,
  BoardType,
} from 'ee_else_ce/boards/constants';
import { DETAIL_VIEW_QUERY_PARAM_NAME } from '~/work_items/constants';
import { calculateNewPosition } from 'ee_else_ce/boards/boards_util';
import { setError } from '../graphql/cache_updates';
import BoardColumn from './board_column.vue';
import BoardDrawerWrapper from './board_drawer_wrapper.vue';

export default {
  draggableItemTypes: DraggableItemTypes,
  components: {
    BoardAddNewColumn,
    BoardAddNewColumnTrigger,
    BoardColumn,
    BoardDrawerWrapper,
    BoardContentSidebar: () => import('~/boards/components/board_content_sidebar.vue'),
    EpicBoardContentSidebar: () =>
      import('ee_component/boards/components/epic_board_content_sidebar.vue'),
    EpicsSwimlanes: () => import('ee_component/boards/components/epics_swimlanes.vue'),
    GlAlert,
    WorkItemDrawer,
  },
  inject: [
    'boardType',
    'canAdminList',
    'isIssueBoard',
    'isEpicBoard',
    'disabled',
    'issuableType',
    'isGroupBoard',
    'fullPath',
    'commentTemplatePaths',
  ],
  props: {
    boardId: {
      type: String,
      required: true,
    },
    filterParams: {
      type: Object,
      required: true,
    },
    isSwimlanesOn: {
      type: Boolean,
      required: true,
    },
    boardLists: {
      type: Object,
      required: false,
      default: () => {},
    },
    error: {
      type: String,
      required: false,
      default: null,
    },
    listQueryVariables: {
      type: Object,
      required: true,
    },
    addColumnFormVisible: {
      type: Boolean,
      required: true,
    },
    useWorkItemDrawer: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      boardHeight: null,
      highlightedLists: [],
      columnsThatCannotFindActiveItem: 0,
    };
  },
  computed: {
    boardListsById() {
      return this.boardLists;
    },
    boardListsToUse() {
      const lists = this.boardLists;
      return sortBy([...Object.values(lists)], 'position');
    },
    canDragColumns() {
      return this.canAdminList;
    },
    boardColumnWrapper() {
      return this.canDragColumns ? Draggable : 'div';
    },
    draggableOptions() {
      const options = {
        ...defaultSortableOptions,
        disabled: this.disabled,
        draggable: '.is-draggable',
        fallbackOnBody: false,
        group: 'boards-list',
        tag: 'div',
        value: this.boardListsToUse,
        delay: DRAG_DELAY,
        delayOnTouchOnly: true,
        filter: 'input',
        preventOnFilter: false,
      };

      return this.canDragColumns ? options : {};
    },
    backlogListId() {
      const backlogList = this.boardListsToUse.find((list) => list.listType === ListType.backlog);
      return backlogList?.id || '';
    },
    closedListId() {
      const closedList = this.boardListsToUse.find((list) => list.listType === ListType.closed);
      return closedList?.id || '';
    },
    namespace() {
      return this.isGroupBoard ? BoardType.group : BoardType.project;
    },
  },
  methods: {
    afterFormEnters() {
      const el = this.canDragColumns ? this.$refs.list.$el : this.$refs.list;
      el.scrollTo({ left: el.scrollWidth, behavior: 'smooth' });
    },
    highlightList(listId) {
      this.highlightedLists.push(listId);

      setTimeout(() => {
        this.highlightedLists = this.highlightedLists.filter((id) => id !== listId);
      }, flashAnimationDuration);
    },
    dismissError() {
      setError({ message: null, captureError: false });
    },
    async updateListPosition({
      item: {
        dataset: { listId: movedListId, draggableItemType },
      },
      newIndex,
      to: { children },
    }) {
      if (draggableItemType !== DraggableItemTypes.list) {
        return;
      }

      const displacedListId = children[newIndex].dataset.listId;

      if (movedListId === displacedListId) {
        return;
      }
      const initialPosition = this.boardListsById[movedListId].position;
      const targetPosition = this.boardListsById[displacedListId].position;

      try {
        await this.$apollo.mutate({
          mutation: updateListQueries[this.issuableType].mutation,
          variables: {
            listId: movedListId,
            position: targetPosition,
          },
          update: (store) => {
            const sourceData = store.readQuery({
              query: listsQuery[this.issuableType].query,
              variables: this.listQueryVariables,
            });
            const data = produce(sourceData, (draftData) => {
              // for current list, new position is already set by Apollo via automatic update
              const affectedNodes = draftData[this.boardType].board.lists.nodes.filter(
                (node) => node.id !== movedListId,
              );
              affectedNodes.forEach((node) => {
                // eslint-disable-next-line no-param-reassign
                node.position = calculateNewPosition(
                  node.position,
                  initialPosition,
                  targetPosition,
                );
              });
            });
            store.writeQuery({
              query: listsQuery[this.issuableType].query,
              variables: this.listQueryVariables,
              data,
            });
          },
          optimisticResponse: {
            updateBoardList: {
              __typename: 'UpdateBoardListPayload',
              errors: [],
              list: {
                ...this.boardLists[movedListId],
                position: targetPosition,
              },
            },
          },
        });
      } catch (error) {
        setError({
          error,
          message: s__('Boards|An error occurred while moving the list. Please try again.'),
        });
      }
    },
    updateBoardCard(workItem, activeCard) {
      const { cache } = this.$apollo.provider.clients.defaultClient;

      const variables = {
        id: activeCard.listId,
        filters: this.filterParams,
        fullPath: this.fullPath,
        boardId: this.boardId,
        isGroup: this.isGroupBoard,
        isProject: !this.isGroupBoard,
        first: DEFAULT_BOARD_LIST_ITEMS_SIZE,
      };

      cache.updateQuery(
        { query: listIssuablesQueries[this.issuableType].query, variables },
        (boardList) =>
          mapWorkItemWidgetsToIssuableFields({
            list: boardList,
            workItem,
            isBoard: true,
            namespace: this.namespace,
            type: this.issuableType,
          }),
      );
    },
    isLastList(index) {
      return this.boardListsToUse.length - 1 === index;
    },
    handleCannotFindActiveItem() {
      this.columnsThatCannotFindActiveItem += 1;
      if (this.columnsThatCannotFindActiveItem === this.boardListsToUse.length) {
        updateHistory({
          url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
        });
      }
    },
  },
};
</script>

<template>
  <div v-cloak data-testid="boards-list" class="gl-flex gl-min-h-0 gl-grow gl-flex-col">
    <gl-alert v-if="error" variant="danger" :dismissible="true" @dismiss="dismissError">
      {{ error }}
    </gl-alert>
    <component
      :is="boardColumnWrapper"
      v-if="!isSwimlanesOn"
      ref="list"
      v-bind="draggableOptions"
      class="boards-list gl-w-full gl-overflow-x-auto gl-whitespace-nowrap gl-py-5 gl-pl-0 gl-pr-5 xl:gl-pl-3 xl:gl-pr-6"
      @end="updateListPosition"
    >
      <board-column
        v-for="(list, index) in boardListsToUse"
        :key="index"
        ref="board"
        :column-index="index"
        :board-id="boardId"
        :list="list"
        :filters="filterParams"
        :highlighted-lists="highlightedLists"
        :data-draggable-item-type="$options.draggableItemTypes.list"
        :class="{ '!gl-hidden sm:!gl-inline-block': addColumnFormVisible }"
        :last="isLastList(index)"
        :list-query-variables="listQueryVariables"
        :lists="boardListsById"
        :can-admin-list="canAdminList"
        @highlight-list="highlightList"
        @setActiveList="$emit('setActiveList', $event)"
        @setFilters="$emit('setFilters', $event)"
        @addNewListAfter="$emit('setAddColumnFormVisibility', $event)"
        @cannot-find-active-item="handleCannotFindActiveItem"
      />

      <transition mode="out-in" name="slide" @after-enter="afterFormEnters">
        <div v-if="!addColumnFormVisible && canAdminList" class="gl-inline-block gl-pl-2">
          <board-add-new-column-trigger
            :is-new-list-showing="addColumnFormVisible"
            @setAddColumnFormVisibility="$emit('setAddColumnFormVisibility', $event)"
          />
        </div>
      </transition>

      <transition mode="out-in" name="slide" @after-enter="afterFormEnters">
        <board-add-new-column
          v-if="addColumnFormVisible"
          :board-id="boardId"
          :list-query-variables="listQueryVariables"
          :lists="boardListsById"
          @setAddColumnFormVisibility="$emit('setAddColumnFormVisibility', $event)"
          @highlight-list="highlightList"
        />
      </transition>
    </component>

    <epics-swimlanes
      v-else-if="boardListsToUse.length"
      ref="swimlanes"
      :board-id="boardId"
      :lists="boardListsToUse"
      :can-admin-list="canAdminList"
      :filters="filterParams"
      :highlighted-lists="highlightedLists"
      @setActiveList="$emit('setActiveList', $event)"
      @move-list="updateListPosition"
      @setFilters="$emit('setFilters', $event)"
    >
      <template #create-list-button>
        <div
          v-if="!addColumnFormVisible"
          class="gl-sticky gl-top-5 gl-mt-5 gl-inline-block gl-pl-3"
        >
          <board-add-new-column-trigger
            v-if="canAdminList"
            :is-new-list-showing="addColumnFormVisible"
            @setAddColumnFormVisibility="$emit('setAddColumnFormVisibility', $event)"
          />
        </div>
      </template>
      <div v-if="addColumnFormVisible" class="gl-pl-2">
        <board-add-new-column
          class="gl-sticky gl-top-5"
          :filter-params="filterParams"
          :list-query-variables="listQueryVariables"
          :board-id="boardId"
          :lists="boardListsById"
          @setAddColumnFormVisibility="$emit('setAddColumnFormVisibility', $event)"
          @highlight-list="highlightList"
        />
      </div>
    </epics-swimlanes>
    <board-drawer-wrapper
      v-if="useWorkItemDrawer"
      :backlog-list-id="backlogListId"
      :closed-list-id="closedListId"
    >
      <template
        #default="{
          activeIssuable,
          onDrawerClosed,
          onAttributeUpdated,
          onIssuableDeleted,
          onStateUpdated,
        }"
      >
        <work-item-drawer
          :open="Boolean(activeIssuable && activeIssuable.iid)"
          :active-item="activeIssuable"
          :issuable-type="issuableType"
          :new-comment-template-paths="commentTemplatePaths"
          click-outside-exclude-selector=".board-card"
          @close="
            onDrawerClosed();
            $emit('drawer-closed');
          "
          @work-item-updated="updateBoardCard($event, activeIssuable)"
          @workItemDeleted="onIssuableDeleted(activeIssuable)"
          @attributesUpdated="onAttributeUpdated"
          @workItemStateUpdated="onStateUpdated"
          @workItemTypeChanged="updateBoardCard($event, activeIssuable)"
          @opened="$emit('drawer-opened')"
          @clicked-outside="$emit('drawer-closed')"
        />
      </template>
    </board-drawer-wrapper>

    <template v-else>
      <board-content-sidebar
        v-if="isIssueBoard"
        :backlog-list-id="backlogListId"
        :closed-list-id="closedListId"
        data-testid="issue-boards-sidebar"
      />
      <epic-board-content-sidebar
        v-else-if="isEpicBoard"
        :backlog-list-id="backlogListId"
        :closed-list-id="closedListId"
        data-testid="epic-boards-sidebar"
      />
    </template>
  </div>
</template>
