<script>
/* eslint-disable vue/require-default-prop */
import IssueCardInner from './issue_card_inner.vue';
import eventHub from '../eventhub';
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
    },
    issue: {
      type: Object,
      default: () => ({}),
    },
    issueLinkBase: {
      type: String,
      default: '',
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    index: {
      type: Number,
      default: 0,
    },
    rootPath: {
      type: String,
      default: '',
    },
    groupId: {
      type: Number,
    },
  },
  data() {
    return {
      showDetail: false,
      detailIssue: boardsStore.detail,
    };
  },
  computed: {
    issueDetailVisible() {
      return this.detailIssue.issue && this.detailIssue.issue.id === this.issue.id;
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

      if (this.showDetail) {
        this.showDetail = false;

        if (boardsStore.detail.issue && boardsStore.detail.issue.id === this.issue.id) {
          eventHub.$emit('clearDetailIssue');
        } else {
          eventHub.$emit('newDetailIssue', this.issue);
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
      'user-can-drag': !disabled && issue.id,
      'is-disabled': disabled || !issue.id,
      'is-active': issueDetailVisible,
    }"
    :index="index"
    :data-issue-id="issue.id"
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
