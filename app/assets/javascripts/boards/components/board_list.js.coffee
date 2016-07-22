BoardList = Vue.extend
  props:
    disabled: Boolean
    boardId: [Number, String]
    issues: Array
    query: String
  ready: ->
    Sortable.create this.$els.list,
      group: 'issues'
      disabled: this.disabled
      animation: 150
      scroll: document.getElementById('board-app')
      scrollSensitivity: 150
      scrollSpeed: 50
      forceFallback: true
      fallbackClass: 'is-dragging'
      ghostClass: 'is-ghost'
      onAdd: (e) ->
        fromBoardId = e.from.getAttribute('data-board')
        fromBoardId = parseInt(fromBoardId) || fromBoardId
        toBoardId = e.to.getAttribute('data-board')
        toBoardId = parseInt(toBoardId) || toBoardId
        issueId = parseInt(e.item.getAttribute('data-issue'))

        BoardsStore.moveCardToBoard(fromBoardId, toBoardId, issueId, e.newIndex)
      onUpdate: (e) ->
        console.log e.newIndex, e.oldIndex

Vue.component('board-list', BoardList)
