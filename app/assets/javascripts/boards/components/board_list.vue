<script>
import { GlLoadingIcon, GlIntersectionObserver } from '@gitlab/ui';
import Draggable from 'vuedraggable';
import { mapActions, mapState } from 'vuex';
import { STATUS_CLOSED } from '~/issues/constants';
import { sprintf, __ } from '~/locale';
import { defaultSortableOptions } from '~/sortable/constants';
import { sortableStart, sortableEnd } from '~/sortable/utils';
import Tracking from '~/tracking';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import {
  DEFAULT_BOARD_LIST_ITEMS_SIZE,
  toggleFormEventPrefix,
  DraggableItemTypes,
  listIssuablesQueries,
  ListType,
} from 'ee_else_ce/boards/constants';
import eventHub from '../eventhub';
import BoardCard from './board_card.vue';
import BoardNewIssue from './board_new_issue.vue';

export default {
  draggableItemTypes: DraggableItemTypes,
  name: 'BoardList',
  i18n: {
    loading: __('Loading'),
    loadingMoreboardItems: __('Loading more'),
    showingAllIssues: __('Showing all issues'),
    showingAllEpics: __('Showing all epics'),
  },
  components: {
    BoardCard,
    BoardNewIssue,
    BoardNewEpic: () => import('ee_component/boards/components/board_new_epic.vue'),
    GlLoadingIcon,
    GlIntersectionObserver,
    BoardCardMoveToPosition,
  },
  mixins: [Tracking.mixin()],
  inject: [
    'isEpicBoard',
    'isGroupBoard',
    'disabled',
    'fullPath',
    'boardType',
    'issuableType',
    'isApolloBoard',
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
    boardItems: {
      type: Array,
      required: true,
    },
    filterParams: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      scrollOffset: 250,
      showCount: false,
      showIssueForm: false,
      showEpicForm: false,
      currentList: null,
      isLoadingMore: false,
    };
  },
  apollo: {
    boardList: {
      query: listQuery,
      variables() {
        return {
          id: this.list.id,
          filters: this.filterParams,
        };
      },
      context: {
        isSingleRequest: true,
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
        return !this.isApolloBoard || this.list.collapsed;
      },
      update(data) {
        return data[this.boardType].board.lists.nodes[0];
      },
      context: {
        isSingleRequest: true,
      },
    },
  },
  computed: {
    ...mapState(['pageInfoByListId', 'listsFlags', 'isUpdateIssueOrderInProgress']),
    boardListItems() {
      return this.isApolloBoard
        ? this.currentList?.[`${this.issuableType}s`].nodes || []
        : this.boardItems;
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
    toggleFormEventPrefix() {
      return this.isEpicBoard ? toggleFormEventPrefix.epic : toggleFormEventPrefix.issue;
    },
    boardItemsSizeExceedsMax() {
      return this.list.maxIssueCount > 0 && this.listItemsCount > this.list.maxIssueCount;
    },
    hasNextPage() {
      return this.isApolloBoard
        ? this.currentList?.[`${this.issuableType}s`].pageInfo?.hasNextPage
        : this.pageInfoByListId[this.list.id]?.hasNextPage;
    },
    loading() {
      return this.isApolloBoard
        ? this.$apollo.queries.currentList.loading && !this.isLoadingMore
        : this.listsFlags[this.list.id]?.isLoading;
    },
    loadingMore() {
      return this.isApolloBoard ? this.isLoadingMore : this.listsFlags[this.list.id]?.isLoadingMore;
    },
    epicCreateFormVisible() {
      return this.isEpicBoard && this.list.listType !== STATUS_CLOSED && this.showEpicForm;
    },
    issueCreateFormVisible() {
      return !this.isEpicBoard && this.list.listType !== STATUS_CLOSED && this.showIssueForm;
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
      return this.canMoveIssue && !this.listsFlags[this.list.id]?.addItemToListInProgress
        ? Draggable
        : 'ul';
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
        delay: 100,
        delayOnTouchOnly: true,
      };

      return this.canMoveIssue ? options : {};
    },
    disableScrollingWhenMutationInProgress() {
      return this.hasNextPage && this.isUpdateIssueOrderInProgress;
    },
    showMoveToPosition() {
      return !this.disabled && this.list.listType !== ListType.closed;
    },
  },
  watch: {
    boardListItems() {
      this.$nextTick(() => {
        this.showCount = this.scrollHeight() > Math.ceil(this.listHeight());
      });
    },
    'list.id': {
      handler(id, oldVal) {
        if (id) {
          eventHub.$on(`${this.toggleFormEventPrefix}${this.list.id}`, this.toggleForm);
          eventHub.$on(`scroll-board-list-${this.list.id}`, this.scrollToTop);

          eventHub.$off(`${this.toggleFormEventPrefix}${oldVal}`, this.toggleForm);
          eventHub.$off(`scroll-board-list-${oldVal}`, this.scrollToTop);
        }
      },
      immediate: true,
    },
  },
  beforeDestroy() {
    eventHub.$off(`${this.toggleFormEventPrefix}${this.list.id}`, this.toggleForm);
    eventHub.$off(`scroll-board-list-${this.list.id}`, this.scrollToTop);
  },
  methods: {
    ...mapActions(['fetchItemsForList', 'moveItem']),
    listHeight() {
      return this.listRef?.getBoundingClientRect()?.height || 0;
    },
    scrollHeight() {
      return this.listRef?.scrollHeight || 0;
    },
    scrollTop() {
      return this.listRef.scrollTop + this.listHeight();
    },
    scrollToTop() {
      this.listRef.scrollTop = 0;
    },
    async loadNextPage() {
      if (this.isApolloBoard) {
        this.isLoadingMore = true;
        await this.$apollo.queries.currentList.fetchMore({
          variables: {
            ...this.listQueryVariables,
            id: this.list.id,
            after: this.currentList?.[`${this.issuableType}s`].pageInfo.endCursor,
          },
        });
        this.isLoadingMore = false;
      } else {
        this.fetchItemsForList({ listId: this.list.id, fetchNext: true });
      }
    },
    toggleForm() {
      if (this.isEpicBoard) {
        this.showEpicForm = !this.showEpicForm;
      } else {
        this.showIssueForm = !this.showIssueForm;
      }
    },
    isObservableItem(index) {
      // observe every 6 item of 10 to achieve smooth loading state
      return index !== 0 && index % 6 === 0;
    },
    onReachingListBottom() {
      if (!this.loadingMore && this.hasNextPage) {
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

      sortableStart();
      this.track('drag_card', { label: 'board' });
    },
    handleDragOnEnd({
      newIndex: originalNewIndex,
      oldIndex,
      from,
      to,
      item: {
        dataset: { draggableItemType, itemId, itemIid, itemPath },
      },
    }) {
      if (draggableItemType !== DraggableItemTypes.card) {
        return;
      }

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

      this.moveItem({
        itemId,
        itemIid,
        itemPath,
        fromListId: from.dataset.listId,
        toListId: to.dataset.listId,
        moveBeforeId,
        moveAfterId,
      });
    },
  },
};
</script>

<template>
  <div
    v-show="!list.collapsed"
    class="board-list-component gl-relative gl-h-full gl-display-flex gl-flex-direction-column gl-min-h-0"
    data-qa-selector="board_list_cards_area"
  >
    <div
      v-if="loading"
      class="gl-mt-4 gl-text-center"
      :aria-label="$options.i18n.loading"
      data-testid="board_list_loading"
    >
      <gl-loading-icon size="sm" />
    </div>
    <board-new-issue v-if="issueCreateFormVisible" :list="list" />
    <board-new-epic v-if="epicCreateFormVisible" :list="list" />
    <component
      :is="treeRootWrapper"
      v-show="!loading"
      ref="list"
      v-bind="treeRootOptions"
      :data-board="list.id"
      :data-board-type="list.listType"
      :class="{
        'gl-bg-red-100 gl-rounded-bottom-left-base gl-rounded-bottom-right-base': boardItemsSizeExceedsMax,
        'gl-overflow-hidden': disableScrollingWhenMutationInProgress,
        'gl-overflow-y-auto': !disableScrollingWhenMutationInProgress,
      }"
      draggable=".board-card"
      class="board-list gl-w-full gl-h-full gl-list-style-none gl-mb-0 gl-p-3 gl-pt-0 gl-overflow-x-hidden"
      data-testid="tree-root-wrapper"
      @start="handleDragOnStart"
      @end="handleDragOnEnd"
    >
      <board-card
        v-for="(item, index) in boardListItems"
        ref="issue"
        :key="item.id"
        :index="index"
        :list="list"
        :item="item"
        :data-draggable-item-type="$options.draggableItemTypes.card"
        :show-work-item-type-icon="!isEpicBoard"
      >
        <board-card-move-to-position
          v-if="showMoveToPosition"
          :item="item"
          :index="index"
          :list="list"
          :list-items-length="boardListItems.length"
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
          class="board-list-count gl-text-center gl-text-secondary gl-py-4"
          data-issue-id="-1"
        >
          <gl-loading-icon
            v-if="loadingMore"
            size="sm"
            :label="$options.i18n.loadingMoreboardItems"
          />
          <span v-if="showingAllItems">{{ showingAllItemsText }}</span>
          <span v-else>{{ paginatedIssueText }}</span>
        </li>
      </div>
    </component>
  </div>
</template>
