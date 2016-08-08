(() => {
  const BoardList = Vue.extend({
    props: {
      disabled: Boolean,
      list: Object,
      issues: Array,
      loading: Boolean,
      issueLinkBase: String
    },
    data: function () {
      return {
        scrollOffset: 250,
        loadingMore: false
      };
    },
    methods: {
      listHeight: function () {
        return this.$els.list.getBoundingClientRect().height;
      },
      scrollHeight: function () {
        return this.$els.list.scrollHeight;
      },
      scrollTop: function () {
        return this.$els.list.scrollTop + this.listHeight();
      },
      loadNextPage: function () {
        this.loadingMore = true;
        const getIssues = this.list.nextPage();

        if (getIssues) {
          getIssues.then(() => {
            this.loadingMore = false;
          });
        }
      },
    },
    ready: function () {
      const list = this.list;
      const options = _.extend({
        group: 'issues',
        disabled: this.disabled,
        onAdd: (e) => {
          const fromListId = parseInt(e.from.getAttribute('data-board')),
                toListId = parseInt(e.to.getAttribute('data-board')),
                issueId = parseInt(e.item.getAttribute('data-issue'));

          BoardsStore.moveCardToList(fromListId, toListId, issueId);
        }
      }, gl.boardSortableDefaultOptions);

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
