(() => {
  const BoardList = Vue.extend({
    props: {
      disabled: Boolean,
      boardId: [Number, String],
      filters: Object,
      issues: Array,
      loading: Boolean,
      issueLinkBase: String
    },
    data: function () {
      return {
        scrollOffset: 20,
        loadMore: false
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
      loadFromLastId: function () {

      },
    },
    ready: function () {
      this.sortable = Sortable.create(this.$els.list, {
        sort: false,
        group: 'issues',
        disabled: this.disabled,
        scrollSensitivity: 150,
        scrollSpeed: 50,
        forceFallback: true,
        fallbackClass: 'is-dragging',
        ghostClass: 'is-ghost',
        onAdd: (e) => {
          let fromListId = e.from.getAttribute('data-board');
          fromListId = parseInt(fromListId) || fromListId;
          let toListId = e.to.getAttribute('data-board');
          toListId = parseInt(toListId) || toListId;
          const issueId = parseInt(e.item.getAttribute('data-issue'));

          BoardsStore.moveCardToList(fromListId, toListId, issueId);
        }
      });

      // Scroll event on list to load more
      this.$els.list.onscroll = () => {
        if ((this.scrollTop() > this.scrollHeight() - this.scrollOffset) && !this.loadMore) {
          this.loadFromLastId();
        }
      };
    },
    beforeDestroy: function () {
      this.sortable.destroy();
    }
  });

  Vue.component('board-list', BoardList);
})();
