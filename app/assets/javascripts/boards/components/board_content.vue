<script>
import { GlAlert } from '@gitlab/ui';
import { sortBy } from 'lodash';
import Draggable from 'vuedraggable';
import { mapState, mapActions } from 'vuex';
import eventHub from '~/boards/eventhub';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import { defaultSortableOptions } from '~/sortable/constants';
import { DraggableItemTypes } from 'ee_else_ce/boards/constants';
import BoardColumn from './board_column.vue';

export default {
  draggableItemTypes: DraggableItemTypes,
  components: {
    BoardAddNewColumn,
    BoardColumn,
    BoardContentSidebar: () => import('~/boards/components/board_content_sidebar.vue'),
    EpicBoardContentSidebar: () =>
      import('ee_component/boards/components/epic_board_content_sidebar.vue'),
    EpicsSwimlanes: () => import('ee_component/boards/components/epics_swimlanes.vue'),
    GlAlert,
  },
  inject: ['canAdminList', 'isIssueBoard', 'isEpicBoard', 'disabled', 'isApolloBoard'],
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
    boardListsApollo: {
      type: Object,
      required: false,
      default: () => {},
    },
    apolloError: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      boardHeight: null,
    };
  },
  computed: {
    ...mapState(['boardLists', 'error', 'addColumnForm']),
    addColumnFormVisible() {
      return this.addColumnForm?.visible;
    },
    boardListsToUse() {
      const lists = this.isApolloBoard ? this.boardListsApollo : this.boardLists;
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
        delay: 100,
        delayOnTouchOnly: true,
        filter: 'input',
        preventOnFilter: false,
      };

      return this.canDragColumns ? options : {};
    },
    errorToDisplay() {
      return this.isApolloBoard ? this.apolloError : this.error;
    },
  },
  created() {
    eventHub.$on('updateBoard', this.refetchLists);
  },
  beforeDestroy() {
    eventHub.$off('updateBoard', this.refetchLists);
  },
  methods: {
    ...mapActions(['moveList', 'unsetError']),
    afterFormEnters() {
      const el = this.canDragColumns ? this.$refs.list.$el : this.$refs.list;
      el.scrollTo({ left: el.scrollWidth, behavior: 'smooth' });
    },
    refetchLists() {
      this.$apollo.queries.boardListsApollo.refetch();
    },
  },
};
</script>

<template>
  <div
    v-cloak
    data-qa-selector="boards_list"
    class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-min-h-0"
  >
    <gl-alert v-if="errorToDisplay" variant="danger" :dismissible="true" @dismiss="unsetError">
      {{ errorToDisplay }}
    </gl-alert>
    <component
      :is="boardColumnWrapper"
      v-if="!isSwimlanesOn"
      ref="list"
      v-bind="draggableOptions"
      class="boards-list gl-w-full gl-py-5 gl-pr-3 gl-white-space-nowrap gl-overflow-x-auto"
      @end="moveList"
    >
      <board-column
        v-for="(list, index) in boardListsToUse"
        :key="index"
        ref="board"
        :board-id="boardId"
        :list="list"
        :filters="filterParams"
        :data-draggable-item-type="$options.draggableItemTypes.list"
        :class="{ 'gl-xs-display-none!': addColumnFormVisible }"
        @setActiveList="$emit('setActiveList', $event)"
      />

      <transition name="slide" @after-enter="afterFormEnters">
        <board-add-new-column v-if="addColumnFormVisible" class="gl-xs-w-full!" />
      </transition>
    </component>

    <epics-swimlanes
      v-else-if="boardListsToUse.length"
      ref="swimlanes"
      :board-id="boardId"
      :lists="boardListsToUse"
      :can-admin-list="canAdminList"
      :filters="filterParams"
      @setActiveList="$emit('setActiveList', $event)"
    />

    <board-content-sidebar v-if="isIssueBoard" data-testid="issue-boards-sidebar" />

    <epic-board-content-sidebar v-else-if="isEpicBoard" data-testid="epic-boards-sidebar" />
  </div>
</template>
