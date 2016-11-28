/* eslint-disable */
//= require ./board_card
//= require ./board_new_issue

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardList = Vue.extend({
    template: '#js-board-list-template',
    components: {
      'board-card': gl.issueBoards.BoardCard,
      'board-new-issue': gl.issueBoards.BoardNewIssue
    },
    props: {
      disabled: Boolean,
      list: Object,
      issues: Array,
      loading: Boolean,
      issueLinkBase: String,
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
            this.list.page++;
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
        group: 'issues',
        sort: false,
        disabled: this.disabled,
        filter: '.board-list-count, .is-disabled',
        onStart: (e) => {
          const card = this.$refs.issue[e.oldIndex];

          card.showDetail = false;
          Store.moving.issue = card.issue;
          Store.moving.list = card.list;

          gl.issueBoards.onStart();
        },
        onAdd: (e) => {
          gl.issueBoards.BoardsStore.moveIssueToList(Store.moving.list, this.list, Store.moving.issue);

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
})();
