<script>
import Draggable from 'vuedraggable';
import { mapActions, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import defaultSortableConfig from '~/sortable/sortable_config';
import { sortableStart, sortableEnd } from '~/boards/mixins/sortable_default_options';
import BoardNewIssue from './board_new_issue_new.vue';
import BoardCard from './board_card.vue';
import eventHub from '../eventhub';
import boardsStore from '../stores/boards_store';
import { sprintf, __ } from '~/locale';

export default {
  name: 'BoardList',
  components: {
    BoardCard,
    BoardNewIssue,
    GlLoadingIcon,
  },
  props: {
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
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
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
    ...mapState(['pageInfoByListId', 'listsFlags']),
    paginatedIssueText() {
      return sprintf(__('Showing %{pageSize} of %{total} issues'), {
        pageSize: this.issues.length,
        total: this.list.issuesSize,
      });
    },
    issuesSizeExceedsMax() {
      return this.list.maxIssueCount > 0 && this.list.issuesSize > this.list.maxIssueCount;
    },
    hasNextPage() {
      return this.pageInfoByListId[this.list.id].hasNextPage;
    },
    loading() {
      return this.listsFlags[this.list.id]?.isLoading;
    },
    listRef() {
      // When  list is draggable, the reference to the list needs to be accessed differently
      return this.canAdminList ? this.$refs.list.$el : this.$refs.list;
    },
    treeRootWrapper() {
      return this.canAdminList ? Draggable : 'ul';
    },
    treeRootOptions() {
      const options = {
        ...defaultSortableConfig,
        fallbackOnBody: false,
        group: 'boards-list',
        tag: 'ul',
        'ghost-class': 'board-card-drag-active',
        'data-list-id': this.list.id,
        value: this.issues,
      };

      return this.canAdminList ? options : {};
    },
  },
  watch: {
    filters: {
      handler() {
        this.list.loadingMore = false;
        this.listRef.scrollTop = 0;
      },
      deep: true,
    },
    issues() {
      this.$nextTick(() => {
        this.showCount = this.scrollHeight() > Math.ceil(this.listHeight());
      });
    },
  },
  created() {
    eventHub.$on(`toggle-issue-form-${this.list.id}`, this.toggleForm);
    eventHub.$on(`scroll-board-list-${this.list.id}`, this.scrollToTop);
  },
  mounted() {
    // Scroll event on list to load more
    this.listRef.addEventListener('scroll', this.onScroll);
  },
  beforeDestroy() {
    eventHub.$off(`toggle-issue-form-${this.list.id}`, this.toggleForm);
    eventHub.$off(`scroll-board-list-${this.list.id}`, this.scrollToTop);
    this.listRef.removeEventListener('scroll', this.onScroll);
  },
  methods: {
    ...mapActions(['fetchIssuesForList', 'moveIssue']),
    listHeight() {
      return this.listRef.getBoundingClientRect().height;
    },
    scrollHeight() {
      return this.listRef.scrollHeight;
    },
    scrollTop() {
      return this.listRef.scrollTop + this.listHeight();
    },
    scrollToTop() {
      this.listRef.scrollTop = 0;
    },
    loadNextPage() {
      const loadingDone = () => {
        this.list.loadingMore = false;
      };
      this.list.loadingMore = true;
      this.fetchIssuesForList({ listId: this.list.id, fetchNext: true })
        .then(loadingDone)
        .catch(loadingDone);
    },
    toggleForm() {
      this.showIssueForm = !this.showIssueForm;
    },
    onScroll() {
      window.requestAnimationFrame(() => {
        if (
          !this.list.loadingMore &&
          this.scrollTop() > this.scrollHeight() - this.scrollOffset &&
          this.hasNextPage
        ) {
          this.loadNextPage();
        }
      });
    },
    handleDragOnStart() {
      sortableStart();
    },
    handleDragOnEnd(params) {
      sortableEnd();
      const { newIndex, oldIndex, from, to, item } = params;
      const { issueId, issueIid, issuePath } = item.dataset;
      const { children } = to;
      let moveBeforeId;
      let moveAfterId;

      const getIssueId = el => Number(el.dataset.issueId);

      // If issue is being moved within the same list
      if (from === to) {
        if (newIndex > oldIndex && children.length > 1) {
          // If issue is being moved down we look for the issue that ends up before
          moveBeforeId = getIssueId(children[newIndex]);
        } else if (newIndex < oldIndex && children.length > 1) {
          // If issue is being moved up we look for the issue that ends up after
          moveAfterId = getIssueId(children[newIndex]);
        } else {
          // If issue remains in the same list at the same position we do nothing
          return;
        }
      } else {
        // We look for the issue that ends up before the moved issue if it exists
        if (children[newIndex - 1]) {
          moveBeforeId = getIssueId(children[newIndex - 1]);
        }
        // We look for the issue that ends up after the moved issue if it exists
        if (children[newIndex]) {
          moveAfterId = getIssueId(children[newIndex]);
        }
      }

      this.moveIssue({
        issueId,
        issueIid,
        issuePath,
        fromListId: from.dataset.listId,
        toListId: to.dataset.listId,
        moveBeforeId,
        moveAfterId,
      });
    },
  },
};
</script>

<template>
  <div
    v-show="list.isExpanded"
    class="board-list-component gl-relative gl-h-full gl-display-flex gl-flex-direction-column"
    data-qa-selector="board_list_cards_area"
  >
    <div
      v-if="loading"
      class="gl-mt-4 gl-text-center"
      :aria-label="__('Loading issues')"
      data-testid="board_list_loading"
    >
      <gl-loading-icon />
    </div>
    <board-new-issue v-if="list.type !== 'closed' && showIssueForm" :list="list" />
    <component
      :is="treeRootWrapper"
      v-show="!loading"
      ref="list"
      v-bind="treeRootOptions"
      :data-board="list.id"
      :data-board-type="list.type"
      :class="{ 'bg-danger-100': issuesSizeExceedsMax }"
      class="board-list gl-w-full gl-h-full gl-list-style-none gl-mb-0 gl-p-2 js-board-list"
      data-testid="tree-root-wrapper"
      @start="handleDragOnStart"
      @end="handleDragOnEnd"
    >
      <board-card
        v-for="(issue, index) in issues"
        ref="issue"
        :key="issue.id"
        :index="index"
        :list="list"
        :issue="issue"
        :disabled="disabled"
      />
      <li v-if="showCount" class="board-list-count gl-text-center" data-issue-id="-1">
        <gl-loading-icon v-show="list.loadingMore" label="Loading more issues" />
        <span v-if="issues.length === list.issuesSize">{{ __('Showing all issues') }}</span>
        <span v-else>{{ paginatedIssueText }}</span>
      </li>
    </component>
  </div>
</template>
