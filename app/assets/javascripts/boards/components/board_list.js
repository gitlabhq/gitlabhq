/* eslint-disable comma-dangle, space-before-function-paren, max-len */
/* global Vue */
/* global Sortable */

import boardNewIssue from './board_new_issue';
import boardCard from './board_card';

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardList = Vue.extend({
    template: '#js-board-list-template',
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
      toggleForm() {
        this.showIssueForm = !this.showIssueForm;
      },
    },
    created() {
      gl.IssueBoardsApp.$on(`hide-issue-form-${this.list.id}`, this.toggleForm);
    },
    mounted () {
      const options = gl.issueBoards.getBoardSortableDefaultOptions({
        scroll: document.querySelectorAll('.boards-list')[0],
        group: 'issues',
        disabled: this.disabled,
        filter: '.board-list-count, .is-disabled',
        dataIdAttr: 'data-issue-id',
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
        onUpdate: (e) => {
          const sortedArray = this.sortable.toArray().filter(id => id !== '-1');
          gl.issueBoards.BoardsStore.moveIssueInList(this.list, Store.moving.issue, e.oldIndex, e.newIndex, sortedArray);
        },
        onMove(e) {
          return !e.related.classList.contains('board-list-count');
        }
      });

      this.sortable = Sortable.create(this.$refs.list, options);

      // Scroll event on list to load more
      this.$refs.list.onscroll = () => {
        if ((this.scrollTop() > this.scrollHeight() - this.scrollOffset) && !this.list.loadingMore) {
          this.loadNextPage();
        }
      };
    },
    beforeDestroy() {
      gl.IssueBoardsApp.$off(`hide-issue-form-${this.list.id}`, this.toggleForm);
    },
  });
})();
