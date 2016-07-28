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
        return typeof this.board.id !== 'number';
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
          BoardsStore.moveBoard(e.oldIndex + 1, e.newIndex + 1);
        }
      });
    },
    beforeDestroy: function () {
      this.sortable.destroy();
    }
  });

  Vue.component('board', Board)
}());
