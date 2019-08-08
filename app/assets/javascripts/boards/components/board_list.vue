<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import Sortable from 'sortablejs';
import { GlLoadingIcon } from '@gitlab/ui';
import boardNewIssue from './board_new_issue.vue';
import boardCard from './board_card.vue';
import eventHub from '../eventhub';
import boardsStore from '../stores/boards_store';
import { getBoardSortableDefaultOptions, sortableStart } from '../mixins/sortable_default_options';

export default {
  name: 'BoardList',
  components: {
    boardCard,
    boardNewIssue,
    GlLoadingIcon,
  },
  props: {
    groupId: {
      type: Number,
      required: false,
      default: 0,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    list: {
      type: Object,
      required: true,
    },
    issues: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      scrollOffset: 250,
      filters: boardsStore.state.filters,
      showCount: false,
      showIssueForm: false,
    };
  },
  watch: {
    filters: {
      handler() {
        this.list.loadingMore = false;
        this.$refs.list.scrollTop = 0;
      },
      deep: true,
    },
    issues() {
      this.$nextTick(() => {
        if (
          this.scrollHeight() <= this.listHeight() &&
          this.list.issuesSize > this.list.issues.length
        ) {
          this.list.page += 1;
          this.list.getIssues(false).catch(() => {
            // TODO: handle request error
          });
        }

        if (this.scrollHeight() > Math.ceil(this.listHeight())) {
          this.showCount = true;
        } else {
          this.showCount = false;
        }
      });
    },
  },
  created() {
    eventHub.$on(`hide-issue-form-${this.list.id}`, this.toggleForm);
    eventHub.$on(`scroll-board-list-${this.list.id}`, this.scrollToTop);
  },
  mounted() {
    const options = getBoardSortableDefaultOptions({
      scroll: true,
      disabled: this.disabled,
      filter: '.board-list-count, .is-disabled',
      dataIdAttr: 'data-issue-id',
      group: {
        name: 'issues',
        /**
         * Dynamically determine between which containers
         * items can be moved or copied as
         * Assignee lists (EE feature) require this behavior
         */
        pull: (to, from, dragEl, e) => {
          // As per Sortable's docs, `to` should provide
          // reference to exact sortable container on which
          // we're trying to drag element, but either it is
          // a library's bug or our markup structure is too complex
          // that `to` never points to correct container
          // See https://github.com/RubaXa/Sortable/issues/1037
          //
          // So we use `e.target` which is always accurate about
          // which element we're currently dragging our card upon
          // So from there, we can get reference to actual container
          // and thus the container type to enable Copy or Move
          if (e.target) {
            const containerEl =
              e.target.closest('.js-board-list') || e.target.querySelector('.js-board-list');
            const toBoardType = containerEl.dataset.boardType;
            const cloneActions = {
              label: ['milestone', 'assignee'],
              assignee: ['milestone', 'label'],
              milestone: ['label', 'assignee'],
            };

            if (toBoardType) {
              const fromBoardType = this.list.type;
              // For each list we check if the destination list is
              // a the list were we should clone the issue
              const shouldClone = Object.entries(cloneActions).some(
                entry => fromBoardType === entry[0] && entry[1].includes(toBoardType),
              );

              if (shouldClone) {
                return 'clone';
              }
            }
          }

          return true;
        },
        revertClone: true,
      },
      onStart: e => {
        const card = this.$refs.issue[e.oldIndex];

        card.showDetail = false;

        const { list } = card;
        const issue = list.findIssue(Number(e.item.dataset.issueId));
        boardsStore.startMoving(list, issue);

        sortableStart();
      },
      onAdd: e => {
        boardsStore.moveIssueToList(
          boardsStore.moving.list,
          this.list,
          boardsStore.moving.issue,
          e.newIndex,
        );

        this.$nextTick(() => {
          e.item.remove();
        });
      },
      onUpdate: e => {
        const sortedArray = this.sortable.toArray().filter(id => id !== '-1');
        boardsStore.moveIssueInList(
          this.list,
          boardsStore.moving.issue,
          e.oldIndex,
          e.newIndex,
          sortedArray,
        );
      },
      onMove(e) {
        return !e.related.classList.contains('board-list-count');
      },
    });

    this.sortable = Sortable.create(this.$refs.list, options);

    // Scroll event on list to load more
    this.$refs.list.addEventListener('scroll', this.onScroll);
  },
  beforeDestroy() {
    eventHub.$off(`hide-issue-form-${this.list.id}`, this.toggleForm);
    eventHub.$off(`scroll-board-list-${this.list.id}`, this.scrollToTop);
    this.$refs.list.removeEventListener('scroll', this.onScroll);
  },
  methods: {
    listHeight() {
      return this.$refs.list.getBoundingClientRect().height;
    },
    scrollHeight() {
      return this.$refs.list.scrollHeight;
    },
    scrollTop() {
      return this.$refs.list.scrollTop + this.listHeight();
    },
    scrollToTop() {
      this.$refs.list.scrollTop = 0;
    },
    loadNextPage() {
      const getIssues = this.list.nextPage();
      const loadingDone = () => {
        this.list.loadingMore = false;
      };

      if (getIssues) {
        this.list.loadingMore = true;
        getIssues.then(loadingDone).catch(loadingDone);
      }
    },
    toggleForm() {
      this.showIssueForm = !this.showIssueForm;
    },
    onScroll() {
      if (!this.list.loadingMore && this.scrollTop() > this.scrollHeight() - this.scrollOffset) {
        this.loadNextPage();
      }
    },
  },
};
</script>

<template>
  <div
    :class="{ 'd-none': !list.isExpanded, 'd-flex flex-column': list.isExpanded }"
    class="board-list-component position-relative h-100"
  >
    <div v-if="loading" class="board-list-loading text-center" :aria-label="__('Loading issues')">
      <gl-loading-icon />
    </div>
    <board-new-issue
      v-if="list.type !== 'closed' && showIssueForm"
      :group-id="groupId"
      :list="list"
    />
    <ul
      v-show="!loading"
      ref="list"
      :data-board="list.id"
      :data-board-type="list.type"
      :class="{ 'is-smaller': showIssueForm }"
      class="board-list w-100 h-100 list-unstyled mb-0 p-1 js-board-list"
    >
      <board-card
        v-for="(issue, index) in issues"
        ref="issue"
        :key="issue.id"
        :index="index"
        :list="list"
        :issue="issue"
        :issue-link-base="issueLinkBase"
        :group-id="groupId"
        :root-path="rootPath"
        :disabled="disabled"
      />
      <li v-if="showCount" class="board-list-count text-center" data-issue-id="-1">
        <gl-loading-icon v-show="list.loadingMore" label="Loading more issues" />
        <span v-if="list.issues.length === list.issuesSize">{{ __('Showing all issues') }}</span>
        <span v-else> Showing {{ list.issues.length }} of {{ list.issuesSize }} issues </span>
      </li>
    </ul>
  </div>
</template>
