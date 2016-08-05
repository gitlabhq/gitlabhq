(() => {
  const Board = Vue.extend({
    props: {
      board: Object
    },
    data: function () {
      return {
        filters: BoardsStore.state.filters
      };
    },
    watch: {
      'query': function () {
        if (this.board.canSearch()) {
          this.board.filters = this.getFilterData();
          this.board.getIssues(true);
        }
      },
      'filters': {
        handler: function () {
          this.board.filters = this.getFilterData();
          this.board.getIssues(true);
        },
        deep: true
      }
    },
    methods: {
      clearSearch: function () {
        this.query = '';
      },
      getFilterData: function () {
        const queryData = this.board.canSearch() ? { search: this.query } : {};

        return _.extend(this.filters, queryData);
      }
    },
    computed: {
      isPreset: function () {
        return this.board.type === 'backlog' || this.board.type === 'done' || this.board.type === 'blank';
      }
    },
    ready: function () {
      Sortable.create(this.$el.parentNode, {
        group: 'boards',
        animation: 150,
        draggable: '.is-draggable',
        forceFallback: true,
        fallbackClass: 'is-dragging',
        ghostClass: 'is-ghost',
        onUpdate: function (e) {
          BoardsStore.moveList(e.oldIndex, e.newIndex);
        }
      });
    }
  });

  Vue.component('board', Board)
})();
