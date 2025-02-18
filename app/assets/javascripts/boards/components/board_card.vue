<script>
import Tracking from '~/tracking';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { WORK_ITEM_TYPE_ENUM_INCIDENT } from '~/work_items/constants';
import setSelectedBoardItemsMutation from '~/boards/graphql/client/set_selected_board_items.mutation.graphql';
import unsetSelectedBoardItemsMutation from '~/boards/graphql/client/unset_selected_board_items.mutation.graphql';
import selectedBoardItemsQuery from '~/boards/graphql/client/selected_board_items.query.graphql';
import setActiveBoardItemMutation from 'ee_else_ce/boards/graphql/client/set_active_board_item.mutation.graphql';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import BoardCardInner from './board_card_inner.vue';

export default {
  name: 'BoardCard',
  components: {
    BoardCardInner,
  },
  mixins: [Tracking.mixin()],
  inject: ['disabled', 'isIssueBoard', 'isEpicBoard'],
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
    columnIndex: {
      type: Number,
      required: false,
      default: 0,
    },
    rowIndex: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    activeBoardItem: {
      query: activeBoardItemQuery,
      variables() {
        return {
          isIssue: this.isIssueBoard,
        };
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    selectedBoardItems: {
      query: selectedBoardItemsQuery,
    },
  },
  computed: {
    activeItemId() {
      return this.activeBoardItem?.id;
    },
    isActive() {
      return this.item.id === this.activeItemId;
    },
    multiSelectVisible() {
      return !this.activeItemId && this.selectedBoardItems?.includes(this.item.id);
    },
    isDisabled() {
      return this.disabled || !this.item.id || this.item.isLoading || !this.canAdmin;
    },
    isDraggable() {
      return !this.isDisabled;
    },
    itemColor() {
      return this.item.color;
    },
    cardStyle() {
      return this.itemColor ? { borderLeftColor: this.itemColor } : '';
    },
    formattedItem() {
      return {
        ...this.item,
        assignees: this.item.assignees?.nodes || [],
        labels: this.item.labels?.nodes || [],
      };
    },
    showFocusBackground() {
      return !this.isActive && !this.multiSelectVisible;
    },
    itemPrefix() {
      return this.isEpicBoard ? '&' : '#';
    },
    itemReferencePath() {
      const { referencePath } = this.item;
      return referencePath.split(this.itemPrefix)[0];
    },
    boardItemUniqueId() {
      return `listItem-${this.itemReferencePath}/${getIdFromGraphQLId(this.item.id)}`;
    },
  },
  methods: {
    toggleIssue(e) {
      // Don't do anything if this happened on a no trigger element
      if (e.target.closest('.js-no-trigger')) return;

      if (e.target.closest('.js-no-trigger-title') && (e.ctrlKey || e.metaKey || e.button === 1)) {
        return;
      }

      // we redirect to incident page instead of opening the drawer
      // should be removed when we introduce incident WI type
      if (this.item.type === WORK_ITEM_TYPE_ENUM_INCIDENT) {
        visitUrl(this.item.webUrl);
        return;
      }
      e.preventDefault();

      const isMultiSelect = e.ctrlKey || e.metaKey;
      if (isMultiSelect && gon?.features?.boardMultiSelect) {
        this.toggleBoardItemMultiSelection(this.item);
      } else {
        e.currentTarget.focus();
        this.toggleItem();
        this.track('click_card', { label: 'right_sidebar' });
      }
    },
    async toggleItem() {
      await this.$apollo.mutate({
        mutation: unsetSelectedBoardItemsMutation,
      });
      this.$apollo.mutate({
        mutation: setActiveBoardItemMutation,
        variables: {
          boardItem: this.isActive ? null : this.item,
          listId: this.list.id,
          isIssue: this.isActive ? undefined : this.isIssueBoard,
        },
      });
    },
    async toggleBoardItemMultiSelection(item) {
      if (this.activeItemId) {
        await this.$apollo.mutate({
          mutation: setSelectedBoardItemsMutation,
          variables: {
            itemId: this.activeItemId,
          },
        });
        await this.$apollo.mutate({
          mutation: setActiveBoardItemMutation,
          variables: { boardItem: null, listId: null },
        });
      }
      this.$apollo.mutate({
        mutation: setSelectedBoardItemsMutation,
        variables: {
          itemId: item.id,
        },
      });
    },
    changeFocusInColumn(currentCard, i) {
      // Building a list using data-col-index instead of just traversing the ul is necessary for swimlanes
      const columnCards = [
        ...document.querySelectorAll(
          `button.board-card-button[data-col-index="${this.columnIndex}"]`,
        ),
      ];
      const currentIndex = columnCards.indexOf(currentCard);
      if (currentIndex + i < 0 || currentIndex + i > columnCards.length - 1) {
        return;
      }
      columnCards[currentIndex + i].focus();
    },
    focusNext(e) {
      this.changeFocusInColumn(e.target, 1);
    },
    focusPrev(e) {
      this.changeFocusInColumn(e.target, -1);
    },
    changeFocusInRow(currentCard, i) {
      const currentList = currentCard.closest('ul');
      // Find next in line list/cell with cards. If none, don't move.
      let listSelector = 'board-list';
      // Account for swimlanes using different structure. Swimlanes traverse within their lane.
      if (currentList.classList.contains('board-cell')) {
        listSelector = `board-cell[data-row-index="${this.rowIndex}"]`;
      }
      const lists = [
        ...document.querySelectorAll(`ul.${listSelector}:not(.list-empty):not(.list-collapsed)`),
      ];
      const currentIndex = lists.indexOf(currentList);
      if (currentIndex + i < 0 || currentIndex + i > lists.length - 1) {
        return;
      }
      // Focus the same index if possible, or last card
      const targetCards = lists[currentIndex + i].querySelectorAll('button.board-card-button');
      if (targetCards.length <= this.index) {
        targetCards[targetCards.length - 1].focus();
      } else {
        targetCards[this.index].focus();
      }
    },
    focusLeft(e) {
      this.changeFocusInRow(e.target, -1);
    },
    focusRight(e) {
      this.changeFocusInRow(e.target, 1);
    },
  },
};
</script>

<template>
  <li
    :class="[
      {
        'multi-select gl-border-blue-200 gl-bg-blue-50': multiSelectVisible,
        'gl-cursor-grab': isDraggable,
        'is-active !gl-bg-blue-50 hover:!gl-bg-blue-50': isActive,
        'is-disabled': isDisabled,
        'gl-cursor-not-allowed gl-bg-subtle': item.isLoading,
      },
    ]"
    :index="index"
    :data-item-id="item.id"
    :data-item-iid="item.iid"
    :data-item-path="item.referencePath"
    data-testid="board-card"
    class="board-card gl-border gl-relative gl-mb-3 gl-rounded-base gl-border-section gl-bg-section gl-leading-normal hover:gl-bg-subtle dark:hover:gl-bg-gray-200"
  >
    <button
      :id="boardItemUniqueId"
      :class="[
        {
          'focus:gl-bg-subtle dark:focus:gl-bg-gray-200': showFocusBackground,
          'gl-border-l-4 gl-pl-4 gl-border-l-solid': itemColor,
        },
      ]"
      :aria-label="item.title"
      :data-col-index="columnIndex"
      :data-row-index="rowIndex"
      :style="cardStyle"
      data-testid="board-card-button"
      class="board-card-button gl-block gl-h-full gl-w-full gl-rounded-base gl-border-0 gl-bg-transparent gl-p-4 gl-text-left gl-outline-none focus:gl-focus"
      @click="toggleIssue"
      @keydown.left.exact.prevent="focusLeft"
      @keydown.right.exact.prevent="focusRight"
      @keydown.down.exact.prevent="focusNext"
      @keydown.up.exact.prevent="focusPrev"
    >
      <board-card-inner
        :list="list"
        :item="formattedItem"
        :update-filters="true"
        :index="index"
        :show-work-item-type-icon="showWorkItemTypeIcon"
        @setFilters="$emit('setFilters', $event)"
      >
        <slot></slot>
      </board-card-inner>
    </button>
  </li>
</template>
