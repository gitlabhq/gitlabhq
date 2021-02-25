<script>
import { mapActions, mapGetters, mapState } from 'vuex';
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
    issue: {
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
    ...mapGetters(['isSwimlanesOn']),
    isActive() {
      return this.issue.id === this.activeId;
    },
    multiSelectVisible() {
      return (
        !this.activeId &&
        this.selectedBoardItems.findIndex((boardItem) => boardItem.id === this.issue.id) > -1
      );
    },
  },
  methods: {
    ...mapActions(['toggleBoardItemMultiSelection', 'toggleBoardItem']),
    toggleIssue(e) {
      // Don't do anything if this happened on a no trigger element
      if (e.target.classList.contains('js-no-trigger')) return;

      const isMultiSelect = e.ctrlKey || e.metaKey;
      if (isMultiSelect) {
        this.toggleBoardItemMultiSelection(this.issue);
      } else {
        this.toggleBoardItem({ boardItem: this.issue });
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
      'user-can-drag': !disabled && issue.id,
      'is-disabled': disabled || !issue.id,
      'is-active': isActive,
    }"
    :index="index"
    :data-issue-id="issue.id"
    :data-issue-iid="issue.iid"
    :data-issue-path="issue.referencePath"
    data-testid="board_card"
    class="board-card gl-p-5 gl-rounded-base"
    @mouseup="toggleIssue($event)"
  >
    <board-card-inner :list="list" :item="issue" :update-filters="true" />
  </li>
</template>
