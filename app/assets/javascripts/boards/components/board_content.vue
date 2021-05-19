<script>
import { GlAlert } from '@gitlab/ui';
import { sortBy } from 'lodash';
import Draggable from 'vuedraggable';
import { mapState, mapGetters, mapActions } from 'vuex';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import defaultSortableConfig from '~/sortable/sortable_config';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BoardColumn from './board_column.vue';
import BoardColumnDeprecated from './board_column_deprecated.vue';

export default {
  components: {
    BoardAddNewColumn,
    BoardColumn:
      gon.features?.graphqlBoardLists || gon.features?.epicBoards
        ? BoardColumn
        : BoardColumnDeprecated,
    BoardContentSidebar: () => import('~/boards/components/board_content_sidebar.vue'),
    EpicBoardContentSidebar: () =>
      import('ee_component/boards/components/epic_board_content_sidebar.vue'),
    EpicsSwimlanes: () => import('ee_component/boards/components/epics_swimlanes.vue'),
    GlAlert,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['canAdminList'],
  props: {
    lists: {
      type: Array,
      required: false,
      default: () => [],
    },
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['boardLists', 'error', 'addColumnForm']),
    ...mapGetters(['isSwimlanesOn', 'isEpicBoard']),
    addColumnFormVisible() {
      return this.addColumnForm?.visible;
    },
    boardListsToUse() {
      return this.glFeatures.graphqlBoardLists || this.isSwimlanesOn || this.isEpicBoard
        ? sortBy([...Object.values(this.boardLists)], 'position')
        : this.lists;
    },
    canDragColumns() {
      return (this.isEpicBoard || this.glFeatures.graphqlBoardLists) && this.canAdminList;
    },
    boardColumnWrapper() {
      return this.canDragColumns ? Draggable : 'div';
    },
    draggableOptions() {
      const options = {
        ...defaultSortableConfig,
        disabled: this.disabled,
        draggable: '.is-draggable',
        fallbackOnBody: false,
        group: 'boards-list',
        tag: 'div',
        value: this.boardListsToUse,
      };

      return this.canDragColumns ? options : {};
    },
  },
  methods: {
    ...mapActions(['moveList', 'unsetError']),
    afterFormEnters() {
      const el = this.canDragColumns ? this.$refs.list.$el : this.$refs.list;
      el.scrollTo({ left: el.scrollWidth, behavior: 'smooth' });
    },
    handleDragOnEnd(params) {
      const { item, newIndex, oldIndex, to } = params;

      const listId = item.dataset.id;
      const replacedListId = to.children[newIndex].dataset.id;

      this.moveList({
        listId,
        replacedListId,
        newIndex,
        adjustmentValue: newIndex < oldIndex ? 1 : -1,
      });
    },
  },
};
</script>

<template>
  <div v-cloak data-qa-selector="boards_list">
    <gl-alert v-if="error" variant="danger" :dismissible="true" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <component
      :is="boardColumnWrapper"
      v-if="!isSwimlanesOn"
      ref="list"
      v-bind="draggableOptions"
      class="boards-list gl-w-full gl-py-5 gl-px-3 gl-white-space-nowrap"
      @end="handleDragOnEnd"
    >
      <board-column
        v-for="(list, index) in boardListsToUse"
        :key="index"
        ref="board"
        :can-admin-list="canAdminList"
        :list="list"
        :disabled="disabled"
      />

      <transition name="slide" @after-enter="afterFormEnters">
        <board-add-new-column v-if="addColumnFormVisible" />
      </transition>
    </component>

    <epics-swimlanes
      v-else-if="boardListsToUse.length"
      ref="swimlanes"
      :lists="boardListsToUse"
      :can-admin-list="canAdminList"
      :disabled="disabled"
    />

    <board-content-sidebar
      v-if="isSwimlanesOn || glFeatures.graphqlBoardLists"
      class="boards-sidebar"
      data-testid="issue-boards-sidebar"
    />

    <epic-board-content-sidebar
      v-else-if="isEpicBoard"
      class="boards-sidebar"
      data-testid="epic-boards-sidebar"
    />
  </div>
</template>
