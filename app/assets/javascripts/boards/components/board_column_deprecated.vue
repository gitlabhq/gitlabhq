<script>
// This component is being replaced in favor of './board_column.vue' for GraphQL boards
import Sortable from 'sortablejs';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header_deprecated.vue';
import { getBoardSortableDefaultOptions, sortableEnd } from '../mixins/sortable_default_options';
import boardsStore from '../stores/boards_store';
import BoardList from './board_list_deprecated.vue';

export default {
  components: {
    BoardListHeader,
    BoardList,
  },
  inject: {
    boardId: {
      default: '',
    },
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
  },
  data() {
    return {
      detailIssue: boardsStore.detail,
      filter: boardsStore.filter,
    };
  },
  computed: {
    listIssues() {
      return this.list.issues;
    },
  },
  watch: {
    filter: {
      handler() {
        // eslint-disable-next-line vue/no-mutating-props
        this.list.page = 1;
        this.list.getIssues(true).catch(() => {
          // TODO: handle request error
        });
      },
      deep: true,
    },
    'list.highlighted': {
      handler(highlighted) {
        if (highlighted) {
          this.$nextTick(() => {
            this.$el.scrollIntoView({ behavior: 'smooth', block: 'start' });
          });
        }
      },
      immediate: true,
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
      :class="{ 'board-column-highlighted': list.highlighted }"
    >
      <board-list-header :list="list" :disabled="disabled" />
      <board-list ref="board-list" :disabled="disabled" :issues="listIssues" :list="list" />
    </div>
  </div>
</template>
