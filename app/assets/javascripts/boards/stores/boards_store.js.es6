((w) => {
  w.BoardsStore = {
    state: {
      lists: [],
      done: {},
      filters: {
        author: {},
        assignee: {},
        milestone: {},
      }
    },
    new: function (board) {
      const list = new List(board);
      this.state.lists.push(list);
    },
    removeList: function (id) {
      this.state.lists = _.reject(this.state.lists, (list) => {
        return list.id === id;
      });
    },
    moveList: function (oldIndex, newIndex) {
      const listFrom = _.find(this.state.lists, (list) => {
        return list.index === oldIndex;
      });

      service.updateBoard(listFrom.id, newIndex);

      const listTo = _.find(this.state.lists, (list) => {
        return list.index === newIndex;
      });

      listFrom.index = newIndex;
      if (newIndex > listTo.index) {
        listTo.index--;
      } else {
        listTo.index++;
      }
    },
    moveCardToList: function (listFromId, listToId, issueId, toIndex) {
      const listFrom = _.find(this.state.lists, (list) => {
        return list.id === listFromId;
      });
      const listTo = _.find(this.state.lists, (list) => {
        return list.id === listToId;
      });
      const issueTo = listTo.findIssue(issueId);
      let issue = listFrom.findIssue(issueId);
      const issueLists = this.getListsForIssue(issue);
      listFrom.removeIssue(issue);

      // Add to new boards issues if it doesn't already exist
      if (issueTo) {
        issue = issueTo;
        issue.removeLabel(listFrom.label);
      } else {
        listTo.addIssue(issue, toIndex);
      }

      if (listTo.id === 'done' && listFrom.id !== 'backlog') {
        issueLists.forEach((list) => {
          issue.removeLabel(list.label);
          list.removeIssue(issue);
        });
      }
    },
    getListsForIssue: function (issue) {
      return _.filter(this.state.lists, (list) => {
        return list.findIssue(issue.id);
      });
    },
    clearDone: () => {
      Vue.set(BoardsStore.state, 'done', {});
    }
  };
}(window));
