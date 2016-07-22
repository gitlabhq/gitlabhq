@BoardsStore =
  state: [
    {id: 'backlog', title: 'Backlog', index: 0, search: true, issues: [{ id: 1, title: 'Test', labels: []}]},
    {id: 1, title: 'Frontend', index: 1, label: { title: 'Frontend', backgroundColor: '#44ad8e', textColor: '#ffffff' }, issues: [{ id: 3, title: 'Frontend bug', labels: [{ title: 'Frontend', backgroundColor: '#44ad8e', textColor: '#ffffff' }, { title: 'UX', backgroundColor: '#44ad8e', textColor: '#ffffff' }]}]},
    {id: 'done', title: 'Done', index: 99999999, issues: [{ id: 2, title: 'Testing done', labels: []}]}
  ]
  interaction: {
    dragging: false
  }
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

    # Add to new boards issues and increase count
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
