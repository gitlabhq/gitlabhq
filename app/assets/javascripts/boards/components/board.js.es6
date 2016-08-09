(function () {
  const Board = Vue.extend({
    props: {
      list: Object,
      disabled: Boolean
    },
    data: function () {
      return {
        query: '',
        filters: BoardsStore.state.filters
      };
    },
    watch: {
      'query': function () {
        if (this.list.canSearch()) {
          this.list.filters = this.getFilterData();
          this.list.getIssues(true);
        }
      },
      'filters': {
        handler: function () {
          this.list.page = 1;
          this.list.getIssues(true);
        },
        deep: true
      }
    },
    methods: {
      clearSearch: function () {
        this.query = '';
      },
      getFilterData: function () {
        const queryData = this.list.canSearch() ? { search: this.query } : {};

        return _.extend(queryData, this.filters);
      }
    },
    computed: {
      isPreset: function () {
        return this.list.type === 'backlog' || this.list.type === 'done' || this.list.type === 'blank';
      }
    },
    ready: function () {
      const options = _.extend({
        disabled: this.disabled,
        group: 'boards',
        draggable: '.is-draggable',
        handle: '.js-board-handle',
        onUpdate: function (e) {
          BoardsStore.moveList(e.oldIndex, e.newIndex);
        }
      }, gl.boardSortableDefaultOptions);

      Sortable.create(this.$el.parentNode, options);
    }
  });

  Vue.component('board', Board)
})();
