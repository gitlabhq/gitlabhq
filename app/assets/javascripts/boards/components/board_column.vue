<script>
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import { isListDraggable } from '../boards_util';
import BoardList from './board_list.vue';
import BoardAddNewColumnBetween from './board_add_new_column_between.vue';

export default {
  components: {
    BoardAddNewColumn,
    BoardAddNewColumnBetween,
    BoardListHeader,
    BoardList,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    boardId: {
      type: String,
      required: true,
    },
    filters: {
      type: Object,
      required: true,
    },
    highlightedLists: {
      type: Array,
      required: false,
      default: () => [],
    },
    last: {
      type: Boolean,
      required: false,
      default: false,
    },
    listQueryVariables: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    lists: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    canAdminList: {
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
      showNewForm: false,
      showNewListForm: false,
    };
  },
  computed: {
    createNewPosition() {
      if (this.list.position < 0) {
        return 0;
      }
      return this.list.position + 1;
    },
    highlighted() {
      return this.highlightedLists.includes(this.list.id);
    },
    isListDraggable() {
      return isListDraggable(this.list);
    },
    showAddNewListBetween() {
      return this.canAdminList && !this.last && !this.showNewListForm;
    },
    listQueryVariablesWithCreateNewPosition() {
      return {
        ...this.listQueryVariables,
        position: this.createNewPosition,
      };
    },
  },
  methods: {
    toggleNewForm() {
      this.showNewForm = !this.showNewForm;
    },
    setShowNewListAfter(value) {
      this.showNewListForm = value;
    },
  },
};
</script>

<template>
  <div
    :class="{
      'is-draggable': isListDraggable,
      '-gl-mr-3': !canAdminList && last,
    }"
    class="gl-inline-flex gl-h-full gl-align-top"
    :data-list-id="list.id"
    data-testid="board-list"
  >
    <div
      :class="{
        'is-collapsed gl-w-10': list.collapsed,
        'board-type-assignee': list.listType === 'assignee',
      }"
      class="board is-expandable gl-relative gl-inline-block gl-h-full gl-whitespace-normal gl-px-3 gl-align-top"
    >
      <div
        class="gl-relative gl-flex gl-h-full gl-flex-col gl-rounded-base gl-bg-strong dark:gl-bg-subtle"
        :class="{ 'board-column-highlighted': highlighted }"
      >
        <board-list-header
          :list="list"
          :filter-params="filters"
          :board-id="boardId"
          @toggleNewForm="toggleNewForm"
          @setActiveList="$emit('setActiveList', $event)"
        />
        <board-list
          ref="board-list"
          :board-id="boardId"
          :list="list"
          :filter-params="filters"
          :show-new-form="showNewForm"
          :column-index="columnIndex"
          @toggleNewForm="toggleNewForm"
          @setFilters="$emit('setFilters', $event)"
          @cannot-find-active-item="$emit('cannot-find-active-item')"
        />
      </div>
      <div
        v-if="showAddNewListBetween"
        class="gl-absolute gl-bottom-0 gl-right-0 gl-top-0 gl-z-1 gl-translate-x-1/2"
      >
        <board-add-new-column-between @setAddColumnFormVisibility="setShowNewListAfter" />
      </div>
    </div>
    <div v-if="showNewListForm" class="gl-pl-2 gl-pr-3">
      <board-add-new-column
        :board-id="boardId"
        :list-query-variables="listQueryVariablesWithCreateNewPosition"
        :lists="lists"
        :position="createNewPosition"
        @setAddColumnFormVisibility="setShowNewListAfter"
        @highlight-list="$emit('highlight-list', $event)"
      />
    </div>
  </div>
</template>
