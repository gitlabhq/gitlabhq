<script>
import { mapGetters, mapActions, mapState } from 'vuex';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import { isListDraggable } from '../boards_util';
import BoardList from './board_list.vue';

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
  computed: {
    ...mapState(['filterParams', 'highlightedLists']),
    ...mapGetters(['getBoardItemsByList']),
    highlighted() {
      return this.highlightedLists.includes(this.list.id);
    },
    listItems() {
      return this.getBoardItemsByList(this.list.id);
    },
    isListDraggable() {
      return isListDraggable(this.list);
    },
  },
  watch: {
    filterParams: {
      handler() {
        if (this.list.id && !this.list.collapsed) {
          this.fetchItemsForList({ listId: this.list.id });
        }
      },
      deep: true,
      immediate: true,
    },
    'list.id': {
      handler(id) {
        if (id) {
          this.fetchItemsForList({ listId: this.list.id });
        }
      },
    },
    highlighted: {
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
  methods: {
    ...mapActions(['fetchItemsForList']),
  },
};
</script>

<template>
  <div
    :class="{
      'is-draggable': isListDraggable,
      'is-collapsed': list.collapsed,
      'board-type-assignee': list.listType === 'assignee',
    }"
    :data-id="list.id"
    class="board gl-display-inline-block gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal is-expandable"
    data-qa-selector="board_list"
  >
    <div
      class="board-inner gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base"
      :class="{ 'board-column-highlighted': highlighted }"
    >
      <board-list-header :list="list" :disabled="disabled" />
      <board-list ref="board-list" :disabled="disabled" :board-items="listItems" :list="list" />
    </div>
  </div>
</template>
