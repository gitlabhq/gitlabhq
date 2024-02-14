<script>
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import { isListDraggable } from '../boards_util';
import BoardList from './board_list.vue';

export default {
  components: {
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
  },
  data() {
    return {
      showNewForm: false,
    };
  },
  computed: {
    highlighted() {
      return this.highlightedLists.includes(this.list.id);
    },
    isListDraggable() {
      return isListDraggable(this.list);
    },
  },
  watch: {
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
    toggleNewForm() {
      this.showNewForm = !this.showNewForm;
    },
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
    data-testid="board-list"
  >
    <div
      class="gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base gl-bg-gray-50"
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
        @toggleNewForm="toggleNewForm"
        @setFilters="$emit('setFilters', $event)"
      />
    </div>
  </div>
</template>
