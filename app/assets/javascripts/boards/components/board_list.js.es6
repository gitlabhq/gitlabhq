//= require ./board_card

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardList = Vue.extend({
    components: {
      'board-card': gl.issueBoards.BoardCard
    },
    props: {
      disabled: Boolean,
      list: Object,
      issues: Array,
      loading: Boolean,
      issueLinkBase: String
    },
    data () {
      return {
        scrollOffset: 250,
        filters: Store.state.filters,
        showCount: false
      };
    },
    watch: {
      filters: {
        handler () {
          this.list.loadingMore = false;
          this.$els.list.scrollTop = 0;
        },
        deep: true
      },
      issues () {
        this.$nextTick(() => {
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
        return this.$els.list.getBoundingClientRect().height;
      },
      scrollHeight () {
        return this.$els.list.scrollHeight;
      },
      scrollTop () {
        return this.$els.list.scrollTop + this.listHeight();
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
    ready () {
      const options = gl.issueBoards.getBoardSortableDefaultOptions({
        group: 'issues',
        sort: false,
        disabled: this.disabled,
        filter: '.board-list-count',
        onStart: (e) => {
          const card = this.$refs.issue[e.oldIndex];

          Store.moving.issue = card.issue;
          Store.moving.list = card.list;

          gl.issueBoards.onStart();
        },
        onAdd: (e) => {
          gl.issueBoards.BoardsStore.moveIssueToList(Store.moving.list, this.list, Store.moving.issue);
        },
        onRemove: (e) => {
          this.$refs.issue[e.oldIndex].$destroy(true);
        }
      });

      this.sortable = Sortable.create(this.$els.list, options);

      // Scroll event on list to load more
      this.$els.list.onscroll = () => {
        if ((this.scrollTop() > this.scrollHeight() - this.scrollOffset) && !this.list.loadingMore) {
          this.loadNextPage();
        }
      };
    }
  });
})();
