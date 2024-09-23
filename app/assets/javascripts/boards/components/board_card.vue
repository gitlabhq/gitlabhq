<script>
import Tracking from '~/tracking';
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
  inject: ['disabled', 'isIssueBoard'],
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
  },
  methods: {
    toggleIssue(e) {
      // Don't do anything if this happened on a no trigger element
      if (e.target.closest('.js-no-trigger')) return;

      const isMultiSelect = e.ctrlKey || e.metaKey;
      if (isMultiSelect && gon?.features?.boardMultiSelect) {
        this.toggleBoardItemMultiSelection(this.item);
      } else {
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
  },
};
</script>

<template>
  <li
    :class="[
      {
        'multi-select gl-border-blue-200 gl-bg-blue-50': multiSelectVisible,
        'gl-cursor-grab': isDraggable,
        'is-disabled': isDisabled,
        'is-active gl-bg-blue-50 hover:!gl-bg-blue-50': isActive,
        'gl-cursor-not-allowed gl-bg-gray-10': item.isLoading,
        'gl-border-l-4 gl-pl-4 gl-border-l-solid': itemColor,
      },
    ]"
    :index="index"
    :data-item-id="item.id"
    :data-item-iid="item.iid"
    :data-item-path="item.referencePath"
    :style="cardStyle"
    data-testid="board-card"
    class="board-card gl-border gl-relative gl-mb-3 gl-rounded-base gl-p-4 gl-leading-normal hover:gl-bg-gray-10"
    @click="toggleIssue($event)"
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
  </li>
</template>
