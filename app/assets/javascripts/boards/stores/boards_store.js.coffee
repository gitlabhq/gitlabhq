@BoardsStore =
  state:
    boards: []
    done: {}
    filters:
      author: {}
      assignee: {}
      milestone: {}
  removeBoard: (id) ->
    BoardsStore.state.boards = _.reject BoardsStore.state.boards, (board) ->
      board.id is id
  moveBoard: (oldIndex, newIndex) ->
    boardFrom = _.find BoardsStore.state.boards, (board) ->
      board.index is oldIndex

    service.updateBoard(boardFrom.id, newIndex)

    boardTo = _.find BoardsStore.state.boards, (board) ->
      board.index is newIndex

    boardFrom.index = newIndex
    if newIndex > boardTo.index
      boardTo.index--
    else
      boardTo.index++
  moveCardToBoard: (boardFromId, boardToId, issueId, toIndex) ->
    boardFrom = _.find BoardsStore.state.boards, (board) ->
      board.id is boardFromId
    boardTo = _.find BoardsStore.state.boards, (board) ->
      board.id is boardToId
    issue = _.find boardFrom.issues, (issue) ->
        issue.id is issueId
    issueTo = _.find boardTo.issues, (issue) ->
        issue.id is issueId
    issueBoards = BoardsStore.getBoardsForIssue(issue)

    # Remove the issue from old board
    boardFrom.issues = _.reject boardFrom.issues, (issue) ->
      issue.id is issueId

    # Add to new boards issues if it doesn't already exist
    if issueTo?
      issue = issueTo
    else
      boardTo.issues.splice(toIndex, 0, issue)

    if boardTo.id is 'done' and boardFrom.id != 'backlog'
      BoardsStore.removeIssueFromBoards(issue, issueBoards)
      issue.labels = _.reject issue.labels, (label) ->
        label.title is boardFrom.title
    else
      if boardTo.label?
        BoardsStore.removeIssueFromBoard(issue, boardFrom)
        foundLabel = _.find issue.labels, (label) ->
          label.title is boardTo.title

        unless foundLabel?
          issue.labels.push(boardTo.label)
  removeIssueFromBoards: (issue, boards) ->
    boardLabels = _.map boards, (board) ->
      board.label.title

    boards.issues = _.each boards, (board) ->
      board.issues = _.reject board.issues, (boardIssue) ->
        issue.id is boardIssue.id

    issue.labels = _.reject issue.labels, (label) ->
      boardLabels.indexOf(label.title) != -1
  removeIssueFromBoard: (issue, board) ->
    issue.labels = _.reject issue.labels, (label) ->
      label.title is board.title
  getBoardsForIssue: (issue) ->
    _.filter BoardsStore.state.boards, (board) ->
      foundIssue = _.find board.issues, (boardIssue) ->
        issue?.id == boardIssue?.id
      foundIssue?
  clearDone: ->
    Vue.set(BoardsStore.state, 'done', {})
