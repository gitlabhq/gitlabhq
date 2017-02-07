/* eslint-disable comma-dangle, space-before-function-paren, max-len */
/* global Vue */
/* global Sortable */

const boardCard = require('./board_card');
const boardNewIssue = require('./board_new_issue');

const Store = gl.issueBoards.BoardsStore;

module.exports = Vue.extend({
  name: 'board-list',
  template: `
    <div class="board-list-component">
      <div
          class="board-list-loading text-center"
          v-if="loading">
        <i class="fa fa-spinner fa-spin"></i>
      </div>
      <board-new-issue
        :list="list"
        v-if="canCreateIssue && list.type !== 'done' && showIssueForm">
      </board-new-issue>
      <ul
        class="board-list"
        ref="list"
        v-show="!loading"
        :data-board="list.id"
        :class="{ 'is-smaller': showIssueForm }">
        <board-card
          v-for="(issue, index) in orderedIssues"
          ref="issue"
          :index="index"
          :list="list"
          :issue="issue"
          :issue-link-base="issueLinkBase"
          :root-path="rootPath"
          :disabled="disabled"
          :key="issue.id">
        </board-card>
        <li
          class="board-list-count text-center"
          v-if="showCount">
          <i
            class="fa fa-spinner fa-spin"
            v-show="list.loadingMore"></i>
          <span v-if="list.issues.length === list.issuesSize">
            Showing all issues
          </span>
          <span v-else>
            Showing {{ list.issues.length }} of {{ list.issuesSize }} issues
          </span>
      </ul>
    </div>
  `,
  components: {
    boardCard,
    boardNewIssue,
  },
  props: {
    disabled: Boolean,
    list: Object,
    issues: Array,
    loading: Boolean,
    issueLinkBase: String,
    rootPath: String,
    canCreateIssue: Boolean,
  },
  data () {
    return {
      scrollOffset: 250,
      filters: Store.state.filters,
      showCount: false,
      showIssueForm: false
    };
  },
  watch: {
    filters: {
      handler () {
        this.list.loadingMore = false;
        this.$refs.list.scrollTop = 0;
      },
      deep: true
    },
    issues () {
      this.$nextTick(() => {
        if (this.scrollHeight() <= this.listHeight() && this.list.issuesSize > this.list.issues.length) {
          this.list.page += 1;
          this.list.getIssues(false);
        }

        if (this.scrollHeight() > this.listHeight()) {
          this.showCount = true;
        } else {
          this.showCount = false;
        }
      });
    }
  },
  computed: {
    orderedIssues () {
      return _.sortBy(this.issues, 'priority');
    },
  },
  methods: {
    listHeight () {
      return this.$refs.list.getBoundingClientRect().height;
    },
    scrollHeight () {
      return this.$refs.list.scrollHeight;
    },
    scrollTop () {
      return this.$refs.list.scrollTop + this.listHeight();
    },
    loadNextPage () {
      const getIssues = this.list.nextPage();

      if (getIssues) {
        this.list.loadingMore = true;
        getIssues.then(() => {
          this.list.loadingMore = false;
        });
      }
    },
  },
  mounted () {
    const options = gl.issueBoards.getBoardSortableDefaultOptions({
      scroll: document.querySelectorAll('.boards-list')[0],
      group: 'issues',
      sort: false,
      disabled: this.disabled,
      filter: '.board-list-count, .is-disabled',
      onStart: (e) => {
        const card = this.$refs.issue[e.oldIndex];

        card.showDetail = false;
        Store.moving.list = card.list;
        Store.moving.issue = Store.moving.list.findIssue(+e.item.dataset.issueId);

        gl.issueBoards.onStart();
      },
      onAdd: (e) => {
        gl.issueBoards.BoardsStore.moveIssueToList(Store.moving.list, this.list, Store.moving.issue, e.newIndex);

        this.$nextTick(() => {
          e.item.remove();
        });
      },
    });

    this.sortable = Sortable.create(this.$refs.list, options);

    // Scroll event on list to load more
    this.$refs.list.onscroll = () => {
      if ((this.scrollTop() > this.scrollHeight() - this.scrollOffset) && !this.list.loadingMore) {
        this.loadNextPage();
      }
    };
  }
});
