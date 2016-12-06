/* eslint-disable */
//= require vue
//= require vue-resource
//= require Sortable
//= require_tree ./models
//= require_tree ./stores
//= require_tree ./services
//= require_tree ./mixins
//= require_tree ./filters
//= require ./components/board
//= require ./components/board_sidebar
//= require ./components/new_list_dropdown
//= require ./vue_resource_interceptor

$(() => {
  const $boardApp = document.getElementById('board-app'),
        Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  Store.create();

  gl.IssueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      'board': gl.issueBoards.Board,
      'board-sidebar': gl.issueBoards.BoardSidebar
    },
    data: {
      state: Store.state,
      loading: true,
      endpoint: $boardApp.dataset.endpoint,
      boardId: $boardApp.dataset.boardId,
      disabled: $boardApp.dataset.disabled === 'true',
      issueLinkBase: $boardApp.dataset.issueLinkBase,
      detailIssue: Store.detail
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
      },
    },
    created () {
      gl.boardService = new BoardService(this.endpoint, this.boardId);
    },
    mounted () {
      const interval = new gl.SmartInterval({
        callback: () => {
          this.fetchAll();
        },
        startingInterval: 5 * 1000, // 5 seconds
        maxInterval: 10 * 1000, // 10 seconds
        incrementByFactorOf: 10,
        lazyStart: true,
      });

      Store.disabled = this.disabled;

      this.fetchAll().then(() => {
        this.loading = false;
        interval.start();
      });
    },
    methods: {
      fetchAll() {
        return gl.boardService.all()
          .then((resp) => {
            const data = resp.json();

            // Remove any old lists
            if (this.state.lists.length) {
              const dataListIds = data.map( list => list.id );

              this.state.lists.forEach((list) => {
                if (dataListIds.indexOf(list.id) === -1) {
                  list.destroy(false);
                }
              });
            }

            // Create/Update lists
            data.forEach((board) => {
              const list = Store.findList('id', board.id, false);

              if (list) {
                // If list already exists, update the data
                list.setData(board);
              } else {
                // If list doesn't exist, create a new list
                Store.addList(board);
              }
            });

            this.state.lists = _.sortBy(this.state.lists, 'position');

            Store.addBlankState();
          });
      },
    },
  });

  gl.IssueBoardsSearch = new Vue({
    el: '#js-boards-seach',
    data: {
      filters: Store.state.filters
    },
    mounted () {
      gl.issueBoards.newListDropdownInit();
    }
  });
});
