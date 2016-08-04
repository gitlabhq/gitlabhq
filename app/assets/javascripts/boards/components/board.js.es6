(() => {
  const Board = Vue.extend({
    props: {
      board: Object
    },
    data: () => {
      return {
        filters: BoardsStore.state.filters
      };
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
      this.sortable = Sortable.create(this.$el.parentNode, {
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
    },
    beforeDestroy: function () {
      this.sortable.destroy();
    }
  });

  Vue.component('board', Board)
})();
