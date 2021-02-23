<script>
// This component is being replaced in favor of './board_card.vue' for GraphQL boards
import sidebarEventHub from '~/sidebar/event_hub';
import eventHub from '../eventhub';
import boardsStore from '../stores/boards_store';
import BoardCardLayoutDeprecated from './board_card_layout_deprecated.vue';

export default {
  components: {
    BoardCardLayout: BoardCardLayoutDeprecated,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    issue: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
  methods: {
    // These are methods instead of computed's, because boardsStore is not reactive.
    isActive() {
      return this.getActiveId() === this.issue.id;
    },
    getActiveId() {
      return boardsStore.detail?.issue?.id;
    },
    showIssue({ isMultiSelect }) {
      // If no issues are opened, close all sidebars first
      if (!this.getActiveId()) {
        sidebarEventHub.$emit('sidebar.closeAll');
      }
      if (this.isActive()) {
        eventHub.$emit('clearDetailIssue', isMultiSelect);

        if (isMultiSelect) {
          eventHub.$emit('newDetailIssue', this.issue, isMultiSelect);
        }
      } else {
        eventHub.$emit('newDetailIssue', this.issue, isMultiSelect);
        boardsStore.setListDetail(this.list);
      }
    },
  },
};
</script>

<template>
  <board-card-layout
    data-qa-selector="board_card"
    :issue="issue"
    :list="list"
    :is-active="isActive()"
    v-bind="$attrs"
    @show="showIssue"
  />
</template>
