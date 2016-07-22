#= require vue
#= require Sortable
#= require_tree ./stores
#= require_tree ./components

$ ->
  new Vue
    el: '#board-app'
    data:
      boards: BoardsStore.state
      interaction: BoardsStore.dragging
