(() => {
  const BoardList = Vue.extend({
    props: {
      disabled: Boolean,
      boardId: [Number, String],
      filters: Object,
      issues: Array,
      query: String
    },
    data: () => {
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
        this.loadMore = true;
        setTimeout(() => {
          this.loadMore = false;
        }, 2000);
      },
      customFilter: function (issue) {
        let returnIssue = issue;
        if (this.filters.author && this.filters.author.id) {
          if (!issue.author || issue.author.id !== this.filters.author.id) {
            returnIssue = null;
          }
        }

        if (this.filters.assignee && this.filters.assignee.id) {
          if (!issue.assignee || issue.assignee.id !== this.filters.assignee.id) {
            returnIssue = null;
          }
        }

        if (this.filters.milestone && this.filters.milestone.id) {
          if (!issue.milestone || issue.milestone.id !== this.filters.milestone.id) {
            returnIssue = null;
          }
        }

        return returnIssue;
      }
    },
    ready: function () {
      this.sortable = Sortable.create(this.$els.list, {
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

          BoardsStore.moveCardToList(fromListId, toListId, issueId, e.newIndex);
        },
        onUpdate: (e) => {
          console.log(e.newIndex, e.oldIndex);
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
