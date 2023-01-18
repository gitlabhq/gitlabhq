<script>
import { mapActions, mapState } from 'vuex';
import Tracking from '~/tracking';
import BoardCardInner from './board_card_inner.vue';

export default {
  name: 'BoardCard',
  components: {
    BoardCardInner,
  },
  mixins: [Tracking.mixin()],
  inject: ['disabled'],
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
    index: {
      type: Number,
      default: 0,
      required: false,
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      default: false,
      required: false,
    },
    canAdmin: {
      type: Boolean,
      required: false,
      default: true,
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
    isDisabled() {
      return this.disabled || !this.item.id || this.item.isLoading || !this.canAdmin;
    },
    isDraggable() {
      return !this.isDisabled;
    },
    cardStyle() {
      return this.isColorful && this.item.color ? { borderColor: this.item.color } : '';
    },
    isColorful() {
      return gon?.features?.epicColorHighlight;
    },
    colorClass() {
      return this.isColorful ? 'gl-pl-4 gl-border-l-solid gl-border-4' : '';
    },
  },
  methods: {
    ...mapActions(['toggleBoardItemMultiSelection', 'toggleBoardItem']),
    toggleIssue(e) {
      // Don't do anything if this happened on a no trigger element
      if (e.target.closest('.js-no-trigger')) return;

      const isMultiSelect = e.ctrlKey || e.metaKey;
      if (isMultiSelect && gon?.features?.boardMultiSelect) {
        this.toggleBoardItemMultiSelection(this.item);
      } else {
        this.toggleBoardItem({ boardItem: this.item });
        this.track('click_card', { label: 'right_sidebar' });
      }
    },
  },
};
</script>

<template>
  <li
    data-qa-selector="board_card"
    :class="[
      {
        'multi-select gl-bg-blue-50 gl-border-blue-200': multiSelectVisible,
        'gl-cursor-grab': isDraggable,
        'is-disabled': isDisabled,
        'is-active gl-bg-blue-50': isActive,
        'gl-cursor-not-allowed gl-bg-gray-10': item.isLoading,
      },
      colorClass,
    ]"
    :index="index"
    :data-item-id="item.id"
    :data-item-iid="item.iid"
    :data-item-path="item.referencePath"
    :style="cardStyle"
    data-testid="board_card"
    class="board-card gl-p-5 gl-rounded-base gl-line-height-normal gl-relative gl-mb-3"
    @click="toggleIssue($event)"
  >
    <board-card-inner
      :list="list"
      :item="item"
      :update-filters="true"
      :index="index"
      :show-work-item-type-icon="showWorkItemTypeIcon"
    >
      <slot></slot>
    </board-card-inner>
  </li>
</template>
