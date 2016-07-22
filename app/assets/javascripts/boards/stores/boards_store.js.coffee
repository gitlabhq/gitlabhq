@BoardsStore =
  state: []
  moveBoard: (oldIndex, newIndex) ->
    boardFrom = _.find BoardsStore.state, (board) ->
      board.index is oldIndex

    service.updateBoard(boardFrom.id, newIndex)

    boardTo = _.find BoardsStore.state, (board) ->
      board.index is newIndex

    boardFrom.index = newIndex
    if newIndex > boardTo.index
      boardTo.index--
    else
      boardTo.index++
  moveCardToBoard: (boardFromId, boardToId, issueId, toIndex) ->
    boardFrom = _.find BoardsStore.state, (board) ->
      board.id is boardFromId
    boardTo = _.find BoardsStore.state, (board) ->
      board.id is boardToId
    issue = _.find boardFrom.issues, (issue) ->
        issue.id is issueId

    # Remove the issue from old board
    boardFrom.issues = _.reject boardFrom.issues, (issue) ->
      issue.id is issueId

    # Add to new boards issues
    boardTo.issues.splice(toIndex, 0, issue)

    # If going to done - remove label
    if boardTo.id is 'done' and boardFrom.id != 'backlog'
      issue.labels = _.reject issue.labels, (label) ->
        label.title is boardFrom.title
    else if boardTo.label?
      foundLabel = _.find issue.labels, (label) ->
        label.title is boardTo.label.title

      unless foundLabel?
        issue.labels.push(boardTo.label)
