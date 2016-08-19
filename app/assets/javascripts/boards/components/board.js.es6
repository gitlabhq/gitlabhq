//= require ./board_blank_state
//= require ./board_delete
//= require ./board_list

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.Board = Vue.extend({
    components: {
      'board-list': gl.issueBoards.BoardList,
      'board-delete': gl.issueBoards.BoardDelete,
      'board-blank-state': gl.issueBoards.BoardBlankState
    },
    props: {
      list: Object,
      disabled: Boolean,
      issueLinkBase: String
    },
    data () {
      return {
        query: '',
        filters: Store.state.filters
      };
    },
    watch: {
      query () {
        this.list.filters = this.getFilterData();
        this.list.getIssues(true);
      },
      filters: {
        handler () {
          this.list.page = 1;
          this.list.getIssues(true);
        },
        deep: true
      }
    },
    methods: {
      getFilterData () {
        const filters = this.filters;
        let queryData = { search: this.query };

        Object.keys(filters).forEach((key) => { queryData[key] = filters[key]; });

        return queryData;
      }
    },
    ready () {
      const options = gl.issueBoards.getBoardSortableDefaultOptions({
        disabled: this.disabled,
        group: 'boards',
        draggable: '.is-draggable',
        handle: '.js-board-handle',
        onEnd: (e) => {
          gl.issueBoards.onEnd();

          if (e.newIndex !== undefined && e.oldIndex !== e.newIndex) {
            const order = this.sortable.toArray(),
                  $board = this.$parent.$refs.board[e.oldIndex + 1],
                  list = $board.list;

            $board.$destroy(true);

            this.$nextTick(() => {
              Store.state.lists.splice(e.newIndex, 0, list);
              Store.moveList(list, order);
            });
          }
        }
      });

      this.sortable = Sortable.create(this.$el.parentNode, options);

      // if (gl.issueBoards.touchEnabled) {
      //   this.$on('scroll', () => {
      //     if (!startedDragging) {
      //       this.sortable.option("disabled", true);
      //     }
      //     this.$broadcast('scroll');
      //   });
      //
      //   this.$on('scrollend', () => {
      //     this.sortable.option("disabled", false);
      //     this.$broadcast('scrollend');
      //   });
      // }
    },
    beforeDestroy () {
      Store.state.lists.$remove(this.list);
    }
  });
})();
