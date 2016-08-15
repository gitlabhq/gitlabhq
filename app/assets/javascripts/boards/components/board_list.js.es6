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
        filters: gl.issueBoards.BoardsStore.state.filters
      };
    },
    watch: {
      filters: {
        handler () {
          this.list.loadingMore = false;
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
      const options = gl.getBoardSortableDefaultOptions({
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

            gl.issueBoards.BoardsStore.moveCardToList(fromListId, toListId, issueId);
          }
        });

      if (bp.getBreakpointSize() === 'sm' || bp.getBreakpointSize() === 'xs') {
        options.handle = '.js-card-drag-handle';
      }

      this.sortable = Sortable.create(this.$els.list, options);

      // Scroll event on list to load more
      this.$els.list.onscroll = () => {
        if ((this.scrollTop() > this.scrollHeight() - this.scrollOffset) && !this.list.loadingMore) {
          this.loadNextPage();
        }
      };
    },
    beforeDestroy () {
      this.sortable.destroy();
    }
  });

  Vue.component('board-list', BoardList);
})();
