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
  inject: ['isApolloBoard'],
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
  },
  computed: {
    ...mapState(['filterParams', 'highlightedLists']),
    ...mapGetters(['getBoardItemsByList']),
    highlighted() {
      return this.highlightedLists.includes(this.list.id);
    },
    listItems() {
      return this.isApolloBoard ? [] : this.getBoardItemsByList(this.list.id);
    },
    isListDraggable() {
      return isListDraggable(this.list);
    },
    filtersToUse() {
      return this.isApolloBoard ? this.filters : this.filterParams;
    },
  },
  watch: {
    filterParams: {
      handler() {
        if (!this.isApolloBoard && this.list.id && !this.list.collapsed) {
          this.fetchItemsForList({ listId: this.list.id });
        }
      },
      deep: true,
      immediate: true,
    },
    'list.id': {
      handler(id) {
        if (!this.isApolloBoard && id) {
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
      'is-collapsed gl-w-10': list.collapsed,
      'board-type-assignee': list.listType === 'assignee',
    }"
    :data-list-id="list.id"
    class="board gl-display-inline-block gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal is-expandable"
    data-qa-selector="board_list"
  >
    <div
      class="board-inner gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base gl-bg-gray-50"
      :class="{ 'board-column-highlighted': highlighted }"
    >
      <board-list-header
        :list="list"
        :filter-params="filtersToUse"
        :board-id="boardId"
        @setActiveList="$emit('setActiveList', $event)"
      />
      <board-list
        ref="board-list"
        :board-id="boardId"
        :board-items="listItems"
        :list="list"
        :filter-params="filtersToUse"
      />
    </div>
  </div>
</template>
