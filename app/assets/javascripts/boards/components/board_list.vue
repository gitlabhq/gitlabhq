<script>
import { GlLoadingIcon, GlIntersectionObserver } from '@gitlab/ui';
import Draggable from 'vuedraggable';
import { STATUS_CLOSED } from '~/issues/constants';
import { sprintf, __, s__ } from '~/locale';
import { ESC_KEY_CODE } from '~/lib/utils/keycodes';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import { sortableStart, sortableEnd } from '~/sortable/utils';
import Tracking from '~/tracking';
import { getParameterByName } from '~/lib/utils/url_utility';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import setActiveBoardItemMutation from 'ee_else_ce/boards/graphql/client/set_active_board_item.mutation.graphql';
import BoardNewIssue from 'ee_else_ce/boards/components/board_new_issue.vue';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import {
  DEFAULT_BOARD_LIST_ITEMS_SIZE,
  DraggableItemTypes,
  listIssuablesQueries,
  ListType,
} from 'ee_else_ce/boards/constants';
import { DETAIL_VIEW_QUERY_PARAM_NAME } from '~/work_items/constants';
import {
  addItemToList,
  removeItemFromList,
  updateEpicsCount,
  updateIssueCountAndWeight,
  setError,
} from '../graphql/cache_updates';
import { shouldCloneCard, moveItemVariables } from '../boards_util';
import BoardCard from './board_card.vue';
import BoardCutLine from './board_cut_line.vue';

export default {
  draggableItemTypes: DraggableItemTypes,
  name: 'BoardList',
  i18n: {
    loading: __('Loading'),
    loadingMoreBoardItems: __('Loading more'),
    showingAllIssues: __('Showing all issues'),
    showingAllEpics: __('Showing all epics'),
  },
  components: {
    BoardCard,
    BoardNewIssue,
    BoardCutLine,
    BoardNewEpic: () => import('ee_component/boards/components/board_new_epic.vue'),
    GlLoadingIcon,
    GlIntersectionObserver,
    BoardCardMoveToPosition,
  },
  mixins: [Tracking.mixin()],
  inject: [
    'isEpicBoard',
    'isIssueBoard',
    'isGroupBoard',
    'disabled',
    'fullPath',
    'boardType',
    'issuableType',
  ],
  props: {
    list: {
      type: Object,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
    filterParams: {
      type: Object,
      required: true,
    },
    showNewForm: {
      type: Boolean,
      required: false,
      default: false,
    },
    columnIndex: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      showCount: false,
      currentList: null,
      isLoadingMore: false,
      toListId: null,
      toList: {},
      addItemToListInProgress: false,
      updateIssueOrderInProgress: false,
      dragCancelled: false,
      hasMadeDrawerAttempt: false,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    boardList: {
      query: listQuery,
      variables() {
        return {
          id: this.list.id,
          filters: this.filterParams,
        };
      },
      skip() {
        return this.isEpicBoard;
      },
    },
    currentList: {
      query() {
        return listIssuablesQueries[this.issuableType].query;
      },
      variables() {
        return {
          id: this.list.id,
          ...this.listQueryVariables,
        };
      },
      skip() {
        return this.list.collapsed;
      },
      update(data) {
        return data[this.boardType].board.lists.nodes[0];
      },
      error(error) {
        setError({
          error,
          message: s__('Boards|An error occurred while fetching a list. Please try again.'),
        });
      },
      result({ data }) {
        if (this.hasMadeDrawerAttempt) {
          return;
        }
        const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

        if (!data || !queryParam) {
          return;
        }

        const { iid, full_path: fullPath } = JSON.parse(atob(queryParam));
        const boardItem = this.boardListItems.find(
          (item) => item.iid === iid && item.referencePath.includes(fullPath),
        );

        if (boardItem) {
          this.setActiveWorkItem(boardItem);
        } else {
          this.$emit('cannot-find-active-item');
        }
        this.hasMadeDrawerAttempt = true;
      },
    },
    toList: {
      query() {
        return listIssuablesQueries[this.issuableType].query;
      },
      variables() {
        return {
          id: this.toListId,
          ...this.listQueryVariables,
        };
      },
      skip() {
        return !this.toListId;
      },
      update(data) {
        return data[this.boardType].board.lists.nodes[0];
      },
      error(error) {
        setError({
          error,
          message: sprintf(
            s__('Boards|An error occurred while moving the %{issuableType}. Please try again.'),
            {
              issuableType: this.isEpicBoard ? 'epic' : 'issue',
            },
          ),
        });
      },
    },
  },
  computed: {
    boardListItems() {
      return this.currentList?.[`${this.issuableType}s`].nodes || [];
    },
    beforeCutLine() {
      return this.boardItemsSizeExceedsMax
        ? this.boardListItems.slice(0, this.list.maxIssueCount)
        : this.boardListItems;
    },
    afterCutLine() {
      return this.boardItemsSizeExceedsMax
        ? this.boardListItems.slice(this.list.maxIssueCount)
        : [];
    },
    listQueryVariables() {
      return {
        fullPath: this.fullPath,
        boardId: this.boardId,
        filters: this.filterParams,
        isGroup: this.isGroupBoard,
        isProject: !this.isGroupBoard,
        first: DEFAULT_BOARD_LIST_ITEMS_SIZE,
      };
    },
    listItemsCount() {
      return this.isEpicBoard ? this.list.metadata.epicsCount : this.boardList?.issuesCount;
    },
    paginatedIssueText() {
      return sprintf(__('Showing %{pageSize} of %{total} %{issuableType}'), {
        pageSize: this.boardListItems.length,
        total: this.listItemsCount,
        issuableType: this.isEpicBoard ? 'epics' : 'issues',
      });
    },
    wipLimitText() {
      return sprintf(__('Work in progress limit: %{wipLimit}'), {
        wipLimit: this.list.maxIssueCount,
      });
    },
    boardItemsSizeExceedsMax() {
      return this.list.maxIssueCount > 0 && this.listItemsCount > this.list.maxIssueCount;
    },
    hasNextPage() {
      return this.currentList?.[`${this.issuableType}s`].pageInfo?.hasNextPage;
    },
    loading() {
      return this.$apollo.queries.currentList.loading && !this.isLoadingMore;
    },
    epicCreateFormVisible() {
      return this.isEpicBoard && this.list.listType !== STATUS_CLOSED && this.showNewForm;
    },
    issueCreateFormVisible() {
      return !this.isEpicBoard && this.list.listType !== STATUS_CLOSED && this.showNewForm;
    },
    listRef() {
      // When list is draggable, the reference to the list needs to be accessed differently
      return this.canMoveIssue ? this.$refs.list.$el : this.$refs.list;
    },
    showingAllItems() {
      return this.boardListItems.length === this.listItemsCount;
    },
    showingAllItemsText() {
      return this.isEpicBoard
        ? this.$options.i18n.showingAllEpics
        : this.$options.i18n.showingAllIssues;
    },
    canMoveIssue() {
      return !this.disabled;
    },
    treeRootWrapper() {
      return this.canMoveIssue && !this.addItemToListInProgress ? Draggable : 'ul';
    },
    treeRootOptions() {
      const options = {
        ...defaultSortableOptions,
        fallbackOnBody: false,
        group: 'board-list',
        tag: 'ul',
        'ghost-class': 'board-card-drag-active',
        'data-list-id': this.list.id,
        value: this.boardListItems,
        delay: DRAG_DELAY,
        delayOnTouchOnly: true,
      };

      return this.canMoveIssue ? options : {};
    },
    disableScrollingWhenMutationInProgress() {
      return this.hasNextPage && this.updateIssueOrderInProgress;
    },
    showMoveToPosition() {
      return !this.disabled && this.list.listType !== ListType.closed;
    },
    shouldCloneCard() {
      return shouldCloneCard(this.list.listType, this.toList.listType);
    },
  },
  watch: {
    boardListItems() {
      this.$nextTick(() => {
        this.showCount = this.scrollHeight() > Math.ceil(this.listHeight());
      });
    },
  },
  methods: {
    listHeight() {
      return this.listRef?.getBoundingClientRect()?.height || 0;
    },
    scrollHeight() {
      return this.listRef?.scrollHeight || 0;
    },
    async loadNextPage() {
      this.isLoadingMore = true;
      await this.$apollo.queries.currentList.fetchMore({
        variables: {
          ...this.listQueryVariables,
          id: this.list.id,
          after: this.currentList?.[`${this.issuableType}s`].pageInfo.endCursor,
        },
      });
      this.isLoadingMore = false;
    },
    isObservableItem(index) {
      // observe every 6 item of 10 to achieve smooth loading state
      return index !== 0 && index % 6 === 0;
    },
    onReachingListBottom() {
      if (!this.isLoadingMore && this.hasNextPage) {
        this.showCount = true;
        this.loadNextPage();
      }
    },
    handleDragOnStart({
      item: {
        dataset: { draggableItemType },
      },
    }) {
      if (draggableItemType !== DraggableItemTypes.card) {
        return;
      }

      // Reset dragCancelled flag
      this.dragCancelled = false;
      // Attach listener to detect `ESC` key press to cancel drag.
      document.addEventListener('keyup', this.handleKeyUp.bind(this));

      sortableStart();
      this.track('drag_card', { label: 'board' });
    },
    async handleDragOnEnd({
      newIndex: originalNewIndex,
      oldIndex,
      from,
      to,
      item: {
        dataset: { draggableItemType, itemId, itemIid },
      },
    }) {
      if (draggableItemType !== DraggableItemTypes.card) {
        return;
      }

      // Detach listener as soon as drag ends.
      document.removeEventListener('keyup', this.handleKeyUp.bind(this));
      // Drag was cancelled, prevent reordering.
      if (this.dragCancelled) return;

      sortableEnd();
      let newIndex = originalNewIndex;
      let { children } = to;
      let moveBeforeId;
      let moveAfterId;

      children = Array.from(children).filter((card) => card.classList.contains('board-card'));

      if (newIndex > children.length) {
        newIndex = children.length;
      }

      const getItemId = (el) => el.dataset.itemId;

      // If item is being moved within the same list
      if (from === to) {
        if (newIndex > oldIndex && children.length > 1) {
          // If item is being moved down we look for the item that ends up before
          moveBeforeId = getItemId(children[newIndex]);
        } else if (newIndex < oldIndex && children.length > 1) {
          // If item is being moved up we look for the item that ends up after
          moveAfterId = getItemId(children[newIndex]);
        } else {
          // If item remains in the same list at the same position we do nothing
          return;
        }
      } else {
        // We look for the item that ends up before the moved item if it exists
        if (children[newIndex - 1]) {
          moveBeforeId = getItemId(children[newIndex - 1]);
        }
        // We look for the item that ends up after the moved item if it exists
        if (children[newIndex]) {
          moveAfterId = getItemId(children[newIndex]);
        }
      }

      this.updateIssueOrderInProgress = true;
      await this.moveBoardItem(
        {
          itemId,
          iid: itemIid,
          fromListId: from.dataset.listId,
          toListId: to.dataset.listId,
          moveBeforeId,
          moveAfterId,
        },
        newIndex,
      ).finally(() => {
        this.updateIssueOrderInProgress = false;
      });
    },
    /**
     * This implementation is needed to support `Esc` key press to cancel drag.
     * It matches with what we already shipped in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119311
     */
    handleKeyUp(e) {
      if (e.keyCode === ESC_KEY_CODE) {
        this.dragCancelled = true;
        // Sortable.js internally listens for `mouseup` event on document
        // to register drop event, see https://github.com/SortableJS/Sortable/blob/master/src/Sortable.js#L625
        // We need to manually trigger it to simulate cancel behaviour as VueDraggable doesn't
        // natively support it, see https://github.com/SortableJS/Vue.Draggable/issues/968.
        document.dispatchEvent(new Event('mouseup'));
      }
    },
    isItemInTheList(itemIid) {
      const items = this.toList?.[`${this.issuableType}s`]?.nodes || [];
      return items.some((item) => item.iid === itemIid);
    },
    async moveBoardItem(variables, newIndex) {
      const { fromListId, toListId, iid, itemId } = variables;
      this.toListId = toListId;
      await this.$nextTick(); // we need this next tick to retrieve `toList` from Apollo cache

      const itemToMove = this.boardListItems.find((item) => item.id === itemId);

      if (this.shouldCloneCard && this.isItemInTheList(iid)) {
        return;
      }

      try {
        await this.$apollo.mutate({
          mutation: listIssuablesQueries[this.issuableType].moveMutation,
          variables: {
            ...moveItemVariables({
              ...variables,
              isIssue: !this.isEpicBoard,
              epicId: itemId, // for Epic Boards
              boardId: this.boardId,
              itemToMove,
            }),
          },
          update: (cache, { data: { issuableMoveList } }) =>
            this.updateCacheAfterMovingItem({
              issuableMoveList,
              fromListId,
              toListId,
              newIndex,
              cache,
            }),
          optimisticResponse: {
            issuableMoveList: {
              issuable: itemToMove,
              errors: [],
            },
          },
        });
      } catch (error) {
        setError({
          error,
          message: sprintf(
            s__('Boards|An error occurred while moving the %{issuableType}. Please try again.'),
            {
              issuableType: this.isEpicBoard ? 'epic' : 'issue',
            },
          ),
        });
      }
    },
    updateCacheAfterMovingItem({ issuableMoveList, fromListId, toListId, newIndex, cache }) {
      const { issuable } = issuableMoveList;
      if (!this.shouldCloneCard) {
        removeItemFromList({
          query: listIssuablesQueries[this.issuableType].query,
          variables: { ...this.listQueryVariables, id: fromListId },
          boardType: this.boardType,
          id: issuable.id,
          issuableType: this.issuableType,
          cache,
        });
      }

      addItemToList({
        query: listIssuablesQueries[this.issuableType].query,
        variables: { ...this.listQueryVariables, id: toListId },
        issuable,
        newIndex,
        boardType: this.boardType,
        issuableType: this.issuableType,
        cache,
      });

      this.updateCountAndWeight({ fromListId, toListId, issuable, cache });
    },
    updateCountAndWeight({ fromListId, toListId, issuable, isAddingItem, cache }) {
      if (!this.isEpicBoard) {
        updateIssueCountAndWeight({
          fromListId,
          toListId,
          filterParams: this.filterParams,
          issuable,
          shouldClone: isAddingItem || this.shouldCloneCard,
          cache,
        });
      } else {
        const { issuableType, filterParams } = this;
        updateEpicsCount({
          issuableType,
          toListId,
          fromListId,
          filterParams,
          issuable,
          shouldClone: isAddingItem || this.shouldCloneCard,
          cache,
        });
      }
    },
    async moveToPosition(positionInList, oldIndex, item) {
      try {
        await this.$apollo.mutate({
          mutation: listIssuablesQueries[this.issuableType].moveMutation,
          variables: {
            ...moveItemVariables({
              iid: item.iid,
              itemId: item.id,
              epicId: item.id, // for Epic Boards
              fromListId: this.currentList.id,
              toListId: this.currentList.id,
              isIssue: !this.isEpicBoard,
              boardId: this.boardId,
              itemToMove: item,
            }),
            positionInList,
          },
          optimisticResponse: {
            issuableMoveList: {
              issuable: item,
              errors: [],
            },
          },
          update: (cache, { data: { issuableMoveList } }) => {
            const { issuable } = issuableMoveList;
            removeItemFromList({
              query: listIssuablesQueries[this.issuableType].query,
              variables: { ...this.listQueryVariables, id: this.currentList.id },
              boardType: this.boardType,
              id: issuable.id,
              issuableType: this.issuableType,
              cache,
            });
            if (positionInList === 0 || this.listItemsCount <= this.boardListItems.length) {
              const newIndex = positionInList === 0 ? 0 : this.boardListItems.length - 1;
              addItemToList({
                query: listIssuablesQueries[this.issuableType].query,
                variables: { ...this.listQueryVariables, id: this.currentList.id },
                issuable,
                newIndex,
                boardType: this.boardType,
                issuableType: this.issuableType,
                cache,
              });
            }
          },
        });
      } catch (error) {
        setError({
          error,
          message: sprintf(
            s__('Boards|An error occurred while moving the %{issuableType}. Please try again.'),
            {
              issuableType: this.isEpicBoard ? 'epic' : 'issue',
            },
          ),
        });
      }
    },
    async addListItem(input) {
      this.$emit('toggleNewForm');
      this.addItemToListInProgress = true;
      let issuable;
      try {
        await this.$apollo.mutate({
          mutation: listIssuablesQueries[this.issuableType].createMutation,
          variables: {
            input: this.isEpicBoard
              ? input
              : {
                  ...input,
                  moveAfterId: this.boardListItems[0]?.id,
                  iterationId: this.list.iteration?.id,
                },
          },
          update: (cache, { data: { createIssuable } }) => {
            issuable = createIssuable.issuable;
            addItemToList({
              query: listIssuablesQueries[this.issuableType].query,
              variables: { ...this.listQueryVariables, id: this.currentList.id },
              issuable,
              newIndex: 0,
              boardType: this.boardType,
              issuableType: this.issuableType,
              cache,
            });
            this.updateCountAndWeight({
              fromListId: null,
              toListId: this.list.id,
              issuable,
              isAddingItem: true,
              cache,
            });
          },
          optimisticResponse: {
            createIssuable: {
              errors: [],
              issuable: {
                ...listIssuablesQueries[this.issuableType].optimisticResponse,
                title: input.title,
              },
            },
          },
        });
      } catch (error) {
        setError({
          message: sprintf(
            s__('Boards|An error occurred while creating the %{issuableType}. Please try again.'),
            {
              issuableType: this.isEpicBoard ? 'epic' : 'issue',
            },
          ),
          error,
        });
      } finally {
        this.addItemToListInProgress = false;
        this.setActiveWorkItem(issuable);
      }
    },
    setActiveWorkItem(boardItem) {
      this.$apollo.mutate({
        mutation: setActiveBoardItemMutation,
        variables: {
          boardItem,
          listId: this.list.id,
          isIssue: this.isIssueBoard,
        },
      });
    },
  },
};
</script>

<template>
  <div
    v-show="!list.collapsed"
    class="board-list-component gl-relative gl-flex gl-h-full gl-min-h-0 gl-flex-col"
    data-testid="board-list-cards-area"
  >
    <div
      v-if="loading"
      class="gl-mt-4 gl-text-center"
      :aria-label="$options.i18n.loading"
      data-testid="board_list_loading"
    >
      <gl-loading-icon size="sm" />
    </div>
    <board-new-issue
      v-if="issueCreateFormVisible"
      :list="list"
      :board-id="boardId"
      @toggleNewForm="$emit('toggleNewForm')"
      @addNewIssue="addListItem"
    />
    <board-new-epic
      v-if="epicCreateFormVisible"
      :list="list"
      :board-id="boardId"
      @toggleNewForm="$emit('toggleNewForm')"
      @addNewEpic="addListItem"
    />
    <component
      :is="treeRootWrapper"
      v-show="!loading"
      ref="list"
      v-bind="treeRootOptions"
      :data-board="list.id"
      :data-board-type="list.listType"
      :class="{
        'gl-rounded-bl-base gl-rounded-br-base gl-bg-red-50': boardItemsSizeExceedsMax,
        'gl-overflow-hidden': disableScrollingWhenMutationInProgress,
        'gl-overflow-y-auto': !disableScrollingWhenMutationInProgress,
        'list-empty': !listItemsCount,
        'list-collapsed': list.collapsed,
      }"
      :draggable="canMoveIssue ? '.board-card' : false"
      class="board-list gl-mb-0 gl-h-full gl-w-full gl-list-none gl-overflow-x-hidden gl-p-3 gl-pt-2"
      data-testid="tree-root-wrapper"
      @start="handleDragOnStart"
      @end="handleDragOnEnd"
    >
      <board-card
        v-for="(item, index) in beforeCutLine"
        ref="issue"
        :key="item.id"
        :index="index"
        :list="list"
        :item="item"
        :column-index="columnIndex"
        :data-draggable-item-type="$options.draggableItemTypes.card"
        :show-work-item-type-icon="!isEpicBoard"
        @setFilters="$emit('setFilters', $event)"
      >
        <board-card-move-to-position
          v-if="showMoveToPosition"
          :item="item"
          :index="index"
          :list="list"
          :list-items-length="boardListItems.length"
          @moveToPosition="moveToPosition($event, index, item)"
        />
        <gl-intersection-observer
          v-if="isObservableItem(index)"
          data-testid="board-card-gl-io"
          @appear="onReachingListBottom"
        />
      </board-card>
      <board-cut-line v-if="boardItemsSizeExceedsMax" :cut-line-text="wipLimitText" />
      <board-card
        v-for="(item, index) in afterCutLine"
        ref="issue"
        :key="item.id"
        :index="index + list.maxIssueCount"
        :list="list"
        :item="item"
        :column-index="columnIndex"
        :data-draggable-item-type="$options.draggableItemTypes.card"
        :show-work-item-type-icon="!isEpicBoard"
        :list-items-length="boardListItems.length"
        @setFilters="$emit('setFilters', $event)"
      >
        <board-card-move-to-position
          v-if="showMoveToPosition"
          :item="item"
          :index="index"
          :list="list"
          :list-items-length="boardListItems.length"
          @moveToPosition="moveToPosition($event, index, item)"
        />
        <gl-intersection-observer
          v-if="isObservableItem(index)"
          data-testid="board-card-gl-io"
          @appear="onReachingListBottom"
        />
      </board-card>
      <div>
        <!-- for supporting previous structure with intersection observer -->
        <li
          v-if="showCount"
          class="board-list-count gl-py-4 gl-text-center gl-text-subtle"
          data-issue-id="-1"
        >
          <gl-loading-icon
            v-if="isLoadingMore"
            size="sm"
            :label="$options.i18n.loadingMoreBoardItems"
          />
          <span v-if="showingAllItems">{{ showingAllItemsText }}</span>
          <span v-else>{{ paginatedIssueText }}</span>
        </li>
      </div>
    </component>
  </div>
</template>
