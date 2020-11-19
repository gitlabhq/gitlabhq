<script>
// This component is being replaced in favor of './board_column_new.vue' for GraphQL boards
import Sortable from 'sortablejs';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import EmptyComponent from '~/vue_shared/components/empty_component';
import BoardList from './board_list.vue';
import boardsStore from '../stores/boards_store';
import { getBoardSortableDefaultOptions, sortableEnd } from '../mixins/sortable_default_options';
import { ListType } from '../constants';

export default {
  components: {
    BoardPromotionState: EmptyComponent,
    BoardListHeader,
    BoardList,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  inject: {
    boardId: {
      default: '',
    },
  },
  data() {
    return {
      detailIssue: boardsStore.detail,
      filter: boardsStore.filter,
    };
  },
  computed: {
    showBoardListAndBoardInfo() {
      return this.list.type !== ListType.promotion;
    },
    listIssues() {
      return this.list.issues;
    },
  },
  watch: {
    filter: {
      handler() {
        this.list.page = 1;
        this.list.getIssues(true).catch(() => {
          // TODO: handle request error
        });
      },
      deep: true,
    },
  },
  mounted() {
    const instance = this;

    const sortableOptions = getBoardSortableDefaultOptions({
      disabled: this.disabled,
      group: 'boards',
      draggable: '.is-draggable',
      handle: '.js-board-handle',
      onEnd(e) {
        sortableEnd();

        const sortable = this;

        if (e.newIndex !== undefined && e.oldIndex !== e.newIndex) {
          const order = sortable.toArray();
          const list = boardsStore.findList('id', parseInt(e.item.dataset.id, 10));

          instance.$nextTick(() => {
            boardsStore.moveList(list, order);
          });
        }
      },
    });

    Sortable.create(this.$el.parentNode, sortableOptions);
  },
};
</script>

<template>
  <div
    :class="{
      'is-draggable': !list.preset,
      'is-expandable': list.isExpandable,
      'is-collapsed': !list.isExpanded,
      'board-type-assignee': list.type === 'assignee',
    }"
    :data-id="list.id"
    class="board gl-display-inline-block gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal"
    data-qa-selector="board_list"
  >
    <div
      class="board-inner gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base"
    >
      <board-list-header :can-admin-list="canAdminList" :list="list" :disabled="disabled" />
      <board-list
        v-if="showBoardListAndBoardInfo"
        ref="board-list"
        :disabled="disabled"
        :issues="listIssues"
        :list="list"
      />

      <!-- Will be only available in EE -->
      <board-promotion-state v-if="list.id === 'promotion'" />
    </div>
  </div>
</template>
