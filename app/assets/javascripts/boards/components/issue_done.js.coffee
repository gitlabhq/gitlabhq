IssueDone = Vue.extend
  props:
    done: Object
  methods:
    removeFromAll: ->
      BoardsStore.removeIssueFromBoards(this.done.issue, this.done.boards)
      BoardsStore.clearDone()
    removeFromSingle: ->
      BoardsStore.removeIssueFromBoard(this.done.issue, this.done.board)
      BoardsStore.clearDone()

Vue.component('issue-done', IssueDone)
