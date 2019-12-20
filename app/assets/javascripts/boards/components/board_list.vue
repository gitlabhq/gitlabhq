<script>
import { Sortable, MultiDrag } from 'sortablejs';
import { GlLoadingIcon } from '@gitlab/ui';
import _ from 'underscore';
import boardNewIssue from './board_new_issue.vue';
import boardCard from './board_card.vue';
import eventHub from '../eventhub';
import boardsStore from '../stores/boards_store';
import { sprintf, __ } from '~/locale';
import createFlash from '~/flash';
import {
  getBoardSortableDefaultOptions,
  sortableStart,
  sortableEnd,
} from '../mixins/sortable_default_options';

if (gon.features && gon.features.multiSelectBoard) {
  Sortable.mount(new MultiDrag());
}

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
  computed: {
    paginatedIssueText() {
      return sprintf(__('Showing %{pageSize} of %{total} issues'), {
        pageSize: this.list.issues.length,
        total: this.list.issuesSize,
      });
    },
    issuesSizeExceedsMax() {
      return this.list.maxIssueCount > 0 && this.list.issuesSize > this.list.maxIssueCount;
    },
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
          this.list.issuesSize > this.list.issues.length &&
          this.list.isExpanded
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
    const multiSelectOpts = {};
    if (gon.features && gon.features.multiSelectBoard) {
      multiSelectOpts.multiDrag = true;
      multiSelectOpts.selectedClass = 'js-multi-select';
      multiSelectOpts.animation = 500;
    }

    const options = getBoardSortableDefaultOptions({
      scroll: true,
      disabled: this.disabled,
      filter: '.board-list-count, .is-disabled',
      dataIdAttr: 'data-issue-id',
      removeCloneOnHide: false,
      ...multiSelectOpts,
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
        const { items = [], newIndicies = [] } = e;
        if (items.length) {
          // Not using e.newIndex here instead taking a min of all
          // the newIndicies. Basically we have to find that during
          // a drop what is the index we're going to start putting
          // all the dropped elements from.
          const newIndex = Math.min(...newIndicies.map(obj => obj.index).filter(i => i !== -1));
          const issues = items.map(item =>
            boardsStore.moving.list.findIssue(Number(item.dataset.issueId)),
          );

          boardsStore.moveMultipleIssuesToList({
            listFrom: boardsStore.moving.list,
            listTo: this.list,
            issues,
            newIndex,
          });
        } else {
          boardsStore.moveIssueToList(
            boardsStore.moving.list,
            this.list,
            boardsStore.moving.issue,
            e.newIndex,
          );
          this.$nextTick(() => {
            e.item.remove();
          });
        }
      },
      onUpdate: e => {
        const sortedArray = this.sortable.toArray().filter(id => id !== '-1');

        const { items = [], newIndicies = [], oldIndicies = [] } = e;
        if (items.length) {
          const newIndex = Math.min(...newIndicies.map(obj => obj.index));
          const issues = items.map(item =>
            boardsStore.moving.list.findIssue(Number(item.dataset.issueId)),
          );
          boardsStore.moveMultipleIssuesInList({
            list: this.list,
            issues,
            oldIndicies: oldIndicies.map(obj => obj.index),
            newIndex,
            idArray: sortedArray,
          });
          e.items.forEach(el => {
            Sortable.utils.deselect(el);
          });
          boardsStore.clearMultiSelect();
          return;
        }

        boardsStore.moveIssueInList(
          this.list,
          boardsStore.moving.issue,
          e.oldIndex,
          e.newIndex,
          sortedArray,
        );
      },
      onEnd: e => {
        const { items = [], clones = [], to } = e;

        // This is not a multi select operation
        if (!items.length && !clones.length) {
          sortableEnd();
          return;
        }

        let toList;
        if (to) {
          const containerEl = to.closest('.js-board-list');
          toList = boardsStore.findList('id', Number(containerEl.dataset.board));
        }

        /**
         * onEnd is called irrespective if the cards were moved in the
         * same list or the other list. Don't remove items if it's same list.
         */
        const isSameList = toList && toList.id === this.list.id;

        if (toList && !isSameList && boardsStore.shouldRemoveIssue(this.list, toList)) {
          const issues = items.map(item => this.list.findIssue(Number(item.dataset.issueId)));

          if (_.compact(issues).length && !boardsStore.issuesAreContiguous(this.list, issues)) {
            const indexes = [];
            const ids = this.list.issues.map(i => i.id);
            issues.forEach(issue => {
              const index = ids.indexOf(issue.id);
              if (index > -1) {
                indexes.push(index);
              }
            });

            // Descending sort because splice would cause index discrepancy otherwise
            const sortedIndexes = indexes.sort((a, b) => (a < b ? 1 : -1));

            sortedIndexes.forEach(i => {
              /**
               * **setTimeout and splice each element one-by-one in a loop
               * is intended.**
               *
               * The problem here is all the indexes are in the list but are
               * non-contiguous. Due to that, when we splice all the indexes,
               * at once, Vue -- during a re-render -- is unable to find reference
               * nodes and the entire app crashes.
               *
               * If the indexes are contiguous, this piece of code is not
               * executed. If it is, this is a possible regression. Only when
               * issue indexes are far apart, this logic should ever kick in.
               */
              setTimeout(() => {
                this.list.issues.splice(i, 1);
              }, 0);
            });
          }
        }

        if (!toList) {
          createFlash(__('Something went wrong while performing the action.'));
        }

        if (!isSameList) {
          boardsStore.clearMultiSelect();

          // Since Vue's list does not re-render the same keyed item, we'll
          // remove `multi-select` class to express it's unselected
          if (clones && clones.length) {
            clones.forEach(el => el.classList.remove('multi-select'));
          }

          // Due to some bug which I am unable to figure out
          // Sortable does not deselect some pending items from the
          // source list.
          // We'll just do it forcefully here.
          Array.from(document.querySelectorAll('.js-multi-select') || []).forEach(item => {
            Sortable.utils.deselect(item);
          });

          /**
           * SortableJS leaves all the moving items "as is" on the DOM.
           * Vue picks up and rehydrates the DOM, but we need to explicity
           * remove the "trash" items from the DOM.
           *
           * This is in parity to the logic on single item move from a list/in
           * a list. For reference, look at the implementation of onAdd method.
           */
          this.$nextTick(() => {
            if (items && items.length) {
              items.forEach(item => {
                item.remove();
              });
            }
          });
        }
        sortableEnd();
      },
      onMove(e) {
        return !e.related.classList.contains('board-list-count');
      },
      onSelect(e) {
        const {
          item: { classList },
        } = e;

        if (
          classList &&
          classList.contains('js-multi-select') &&
          !classList.contains('multi-select')
        ) {
          Sortable.utils.deselect(e.item);
        }
      },
      onDeselect: e => {
        const {
          item: { dataset, classList },
        } = e;

        if (
          classList &&
          classList.contains('multi-select') &&
          !classList.contains('js-multi-select')
        ) {
          const issue = this.list.findIssue(Number(dataset.issueId));
          boardsStore.toggleMultiSelect(issue);
        }
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
    data-qa-selector="board_list_cards_area"
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
      :class="{ 'is-smaller': showIssueForm, 'bg-danger-100': issuesSizeExceedsMax }"
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
        <span v-else>{{ paginatedIssueText }}</span>
      </li>
    </ul>
  </div>
</template>
