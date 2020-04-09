<script>
/* eslint-disable vue/require-default-prop */
import IssueCardInner from './issue_card_inner.vue';
import eventHub from '../eventhub';
import sidebarEventHub from '~/sidebar/event_hub';
import boardsStore from '../stores/boards_store';

export default {
  name: 'BoardsIssueCard',
  components: {
    IssueCardInner,
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
    issueLinkBase: {
      type: String,
      default: '',
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
    rootPath: {
      type: String,
      default: '',
      required: false,
    },
    groupId: {
      type: Number,
      required: false,
    },
  },
  data() {
    return {
      showDetail: false,
      detailIssue: boardsStore.detail,
      multiSelect: boardsStore.multiSelect,
    };
  },
  computed: {
    issueDetailVisible() {
      return this.detailIssue.issue && this.detailIssue.issue.id === this.issue.id;
    },
    multiSelectVisible() {
      return this.multiSelect.list.findIndex(issue => issue.id === this.issue.id) > -1;
    },
    canMultiSelect() {
      return gon.features && gon.features.multiSelectBoard;
    },
  },
  methods: {
    mouseDown() {
      this.showDetail = true;
    },
    mouseMove() {
      this.showDetail = false;
    },
    showIssue(e) {
      if (e.target.classList.contains('js-no-trigger')) return;

      // If no issues are opened, close all sidebars first
      if (!boardsStore.detail?.issue?.id) {
        sidebarEventHub.$emit('sidebar.closeAll');
      }

      // If CMD or CTRL is clicked
      const isMultiSelect = this.canMultiSelect && (e.ctrlKey || e.metaKey);

      if (this.showDetail || isMultiSelect) {
        this.showDetail = false;

        if (boardsStore.detail.issue && boardsStore.detail.issue.id === this.issue.id) {
          eventHub.$emit('clearDetailIssue', isMultiSelect);

          if (isMultiSelect) {
            eventHub.$emit('newDetailIssue', this.issue, isMultiSelect);
          }
        } else {
          eventHub.$emit('newDetailIssue', this.issue, isMultiSelect);
          boardsStore.setListDetail(this.list);
        }
      }
    },
  },
};
</script>

<template>
  <li
    :class="{
      'multi-select': multiSelectVisible,
      'user-can-drag': !disabled && issue.id,
      'is-disabled': disabled || !issue.id,
      'is-active': issueDetailVisible,
    }"
    :index="index"
    :data-issue-id="issue.id"
    data-qa-selector="board_card"
    class="board-card p-3 rounded"
    @mousedown="mouseDown"
    @mousemove="mouseMove"
    @mouseup="showIssue($event)"
  >
    <issue-card-inner
      :list="list"
      :issue="issue"
      :issue-link-base="issueLinkBase"
      :group-id="groupId"
      :root-path="rootPath"
      :update-filters="true"
    />
  </li>
</template>
