<script>
import { GlAlert } from '@gitlab/ui';
import { sortBy } from 'lodash';
import produce from 'immer';
import Draggable from 'vuedraggable';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import { s__ } from '~/locale';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import { mapWorkItemWidgetsToIssueFields } from '~/issues/list/utils';
import {
  DraggableItemTypes,
  flashAnimationDuration,
  listsQuery,
  updateListQueries,
  ListType,
  listIssuablesQueries,
  DEFAULT_BOARD_LIST_ITEMS_SIZE,
} from 'ee_else_ce/boards/constants';
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
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'boardType',
    'canAdminList',
    'isIssueBoard',
    'isEpicBoard',
    'disabled',
    'issuableType',
    'isGroupBoard',
    'fullPath',
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
  },
  data() {
    return {
      boardHeight: null,
      highlightedLists: [],
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
    issuesDrawerEnabled() {
      return this.glFeatures.issuesListDrawer;
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
        (boardList) => mapWorkItemWidgetsToIssueFields(boardList, workItem, true),
      );
    },
  },
};
</script>

<template>
  <div
    v-cloak
    data-testid="boards-list"
    class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-min-h-0"
  >
    <gl-alert v-if="error" variant="danger" :dismissible="true" @dismiss="dismissError">
      {{ error }}
    </gl-alert>
    <component
      :is="boardColumnWrapper"
      v-if="!isSwimlanesOn"
      ref="list"
      v-bind="draggableOptions"
      class="boards-list gl-w-full gl-py-5 gl-pl-0 gl-pr-5 xl:gl-pl-3 xl:gl-pr-6 gl-whitespace-nowrap gl-overflow-x-auto"
      @end="updateListPosition"
    >
      <board-column
        v-for="(list, index) in boardListsToUse"
        :key="index"
        ref="board"
        :board-id="boardId"
        :list="list"
        :filters="filterParams"
        :highlighted-lists="highlightedLists"
        :data-draggable-item-type="$options.draggableItemTypes.list"
        :class="{ '!gl-hidden sm:!gl-inline-block': addColumnFormVisible }"
        @setActiveList="$emit('setActiveList', $event)"
        @setFilters="$emit('setFilters', $event)"
      />

      <transition mode="out-in" name="slide" @after-enter="afterFormEnters">
        <div v-if="!addColumnFormVisible" class="gl-display-inline-block gl-pl-2">
          <board-add-new-column-trigger
            v-if="canAdminList"
            :is-new-list-showing="addColumnFormVisible"
            @setAddColumnFormVisibility="$emit('setAddColumnFormVisibility', $event)"
          />
        </div>
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
          class="gl-mt-5 gl-display-inline-block gl-pl-3 gl-sticky gl-top-5"
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
      v-if="issuesDrawerEnabled"
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
          @close="onDrawerClosed"
          @work-item-updated="updateBoardCard($event, activeIssuable)"
          @workItemDeleted="onIssuableDeleted(activeIssuable)"
          @attributesUpdated="onAttributeUpdated"
          @workItemStateUpdated="onStateUpdated"
        />
      </template>
    </board-drawer-wrapper>

    <board-content-sidebar
      v-if="isIssueBoard && !issuesDrawerEnabled"
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
  </div>
</template>
