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
          const data = _.extend(this.filters, { search: this.query });
          this.board.getIssues(data);
        }
      }
    },
    methods: {
      clearSearch: function () {
        this.query = '';
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
