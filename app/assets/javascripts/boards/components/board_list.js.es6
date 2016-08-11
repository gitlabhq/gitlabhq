(() => {
  const BoardList = Vue.extend({
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
        loadingMore: false,
        filters: BoardsStore.state.filters
      };
    },
    watch: {
      filters: {
        handler () {
          this.loadingMore = false;
          this.$els.list.scrollTop = 0;
        },
        deep: true
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
        this.loadingMore = true;
        const getIssues = this.list.nextPage();

        if (getIssues) {
          getIssues.then(() => {
            this.loadingMore = false;
          });
        }
      },
    },
    ready () {
      const list = this.list,
        options = gl.getBoardSortableDefaultOptions({
          group: 'issues',
          sort: false,
          disabled: this.disabled,
          onAdd (e) {
            const card = e.item,
                  fromListId = parseInt(e.from.getAttribute('data-board')),
                  toListId = parseInt(e.to.getAttribute('data-board')),
                  issueId = parseInt(card.getAttribute('data-issue'));

            // Remove the new dom element & let vue add the element
            card.parentNode.removeChild(card);

            BoardsStore.moveCardToList(fromListId, toListId, issueId);
          }
        });

      if (bp.getBreakpointSize() === 'sm' || bp.getBreakpointSize() === 'xs') {
        options.handle = '.js-card-drag-handle';
      }

      Sortable.create(this.$els.list, options);

      // Scroll event on list to load more
      this.$els.list.onscroll = () => {
        if ((this.scrollTop() > this.scrollHeight() - this.scrollOffset) && !this.loadingMore) {
          this.loadNextPage();
        }
      };
    }
  });

  Vue.component('board-list', BoardList);
})();
