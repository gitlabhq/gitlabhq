BoardDelete = Vue.extend
  props:
    boardId: Number
  methods:
    deleteBoard: ->
      $(this.$el).tooltip('destroy')

      if confirm('Are you sure you want to delete this list?')
        BoardsStore.removeBoard(this.boardId)

Vue.component 'board-delete', BoardDelete
