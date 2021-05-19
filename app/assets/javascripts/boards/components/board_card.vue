<script>
import { mapActions, mapState } from 'vuex';
import BoardCardInner from './board_card_inner.vue';

export default {
  name: 'BoardCard',
  components: {
    BoardCardInner,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    item: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    index: {
      type: Number,
      default: 0,
      required: false,
    },
  },
  computed: {
    ...mapState(['selectedBoardItems', 'activeId']),
    isActive() {
      return this.item.id === this.activeId;
    },
    multiSelectVisible() {
      return (
        !this.activeId &&
        this.selectedBoardItems.findIndex((boardItem) => boardItem.id === this.item.id) > -1
      );
    },
  },
  methods: {
    ...mapActions(['toggleBoardItemMultiSelection', 'toggleBoardItem']),
    toggleIssue(e) {
      // Don't do anything if this happened on a no trigger element
      if (e.target.closest('.js-no-trigger')) return;

      const isMultiSelect = e.ctrlKey || e.metaKey;
      if (isMultiSelect) {
        this.toggleBoardItemMultiSelection(this.item);
      } else {
        this.toggleBoardItem({ boardItem: this.item });
      }
    },
  },
};
</script>

<template>
  <li
    data-qa-selector="board_card"
    :class="{
      'multi-select': multiSelectVisible,
      'user-can-drag': !disabled && item.id,
      'is-disabled': disabled || !item.id,
      'is-active': isActive,
    }"
    :index="index"
    :data-item-id="item.id"
    :data-item-iid="item.iid"
    :data-item-path="item.referencePath"
    data-testid="board_card"
    class="board-card gl-p-5 gl-rounded-base"
    @mouseup="toggleIssue($event)"
  >
    <board-card-inner :list="list" :item="item" :update-filters="true" />
  </li>
</template>
