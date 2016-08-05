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
          this.board.getIssues(true);
        }
      },
      'filters': {
        handler: function () {
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

        return _.extend(queryData, this.filters);
      }
    },
    computed: {
      isPreset: function () {
        return this.board.type === 'backlog' || this.board.type === 'done' || this.board.type === 'blank';
      }
    },
    ready: function () {
      const options = _.extend({
        group: 'boards',
        draggable: '.is-draggable',
        handle: '.js-board-handle',
        filter: '.board-delete',
        onUpdate: function (e) {
          BoardsStore.moveList(e.oldIndex, e.newIndex);
        }
      }, gl.boardSortableDefaultOptions);

      Sortable.create(this.$el.parentNode, options);
    }
  });

  Vue.component('board', Board)
})();
