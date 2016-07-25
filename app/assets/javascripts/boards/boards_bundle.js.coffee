#= require vue
#= require vue-resource
#= require Sortable
#= require_tree ./stores
#= require_tree ./services
#= require_tree ./components

$ =>
  @service = new BoardService($('#board-app').data('endpoint'))

  new Vue
    el: '#board-app'
    data:
      state: BoardsStore.state
    ready: ->
      service
        .all()
        .then (resp) ->
          BoardsStore.state.boards.push(board) for board in resp.data
