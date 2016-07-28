((w) => {
  w.BoardsStore = {
    state: {
      boards: [],
      done: {},
      filters: {
        author: {},
        assignee: {},
        milestone: {},
      }
    },
    removeBoard: (id) => {
      BoardsStore.state.boards = _.reject(BoardsStore.state.boards, (board) => {
        return board.id === id;
      });
    },
    moveBoard: (oldIndex, newIndex) => {
      const boardFrom = _.find(BoardsStore.state.boards, (board) => {
        return board.index === oldIndex;
      });

      service.updateBoard(boardFrom.id, newIndex);

      const boardTo = _.find(BoardsStore.state.boards, (board) => {
        return board.index === newIndex;
      });

      boardFrom.index = newIndex;
      if (newIndex > boardTo.index) {
        boardTo.index--;
      } else {
        boardTo.index++;
      }
    },
    moveCardToBoard: (boardFromId, boardToId, issueId, toIndex) => {
      const boardFrom = _.find(BoardsStore.state.boards, (board) => {
        return board.id === boardFromId;
      });
      const boardTo = _.find(BoardsStore.state.boards, (board) => {
        return board.id === boardToId;
      });
      let issue = _.find(boardFrom.issues, (issue) => {
        return issue.id === issueId;
      });
      const issueTo = _.find(boardTo.issues, (issue) => {
        return issue.id === issueId;
      });
      const issueBoards = BoardsStore.getBoardsForIssue(issue);

      // Remove the issue from old board
      boardFrom.issues = _.reject(boardFrom.issues, (issue) => {
        return issue.id === issueId;
      });

      // Add to new boards issues if it doesn't already exist
      if (issueTo !== null) {
        issue = issueTo;
      } else {
        boardTo.issues.splice(toIndex, 0, issue);
      }

      if (boardTo.id === 'done' && boardFrom.id !== 'backlog') {
        BoardsStore.removeIssueFromBoards(issue, issueBoards);
        issue.labels = _.reject(issue.labels, (label) => {
          return label.title === boardFrom.title;
        });
      } else {
        if (boardTo.label !== null) {
          BoardsStore.removeIssueFromBoard(issue, boardFrom);
          foundLabel = _.find(issue.labels, (label) => {
            return label.title === boardTo.title;
          });

          if (foundLabel === null) {
            issue.labels.push(boardTo.label);
          }
        }
      }
    },
    removeIssueFromBoards: (issue, boards) => {
      const boardLabels = _.map(boards, (board) => {
        return board.label.title;
      });

      boards.issues = _.each(boards, (board) => {
        board.issues = _.reject(board.issues, (boardIssue) => {
          return issue.id === boardIssue.id;
        });
      });

      issue.labels = _.reject(issue.labels, (label) => {
        return boardLabels.indexOf(label.title) !== -1;
      });
    },
    removeIssueFromBoard: (issue, board) => {
      issue.labels = _.reject(issue.labels, (label) => {
        return label.title === board.title;
      });
    },
    getBoardsForIssue: (issue) => {
      _.filter(BoardsStore.state.boards, (board) => {
        const foundIssue = _.find(board.issues, (boardIssue) => {
          return issue.id === boardIssue.id;
        });
        return foundIssue !== null;
      });
    },
    clearDone: () => {
      Vue.set(BoardsStore.state, 'done', {});
    }
  };
}(window));
