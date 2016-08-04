((w) => {
  w.BoardsStore = {
    state: {
      lists: [],
      filters: {
        author: {},
        assignee: {},
        milestone: {},
      }
    },
    new: function (board) {
      const doneList = this.getDoneList(),
            list = new List(board);
      this.state.lists.push(list);

      if (list.type !== 'blank') {
        service.createList(list.label.id)
          .then(function (resp) {
            const data = resp.json();

            list.id = data.id;
            list.type = data.list_type;
            list.position = data.position;
          });

        this.removeBlankState();
        this.addBlankState();
      }
    },
    addBlankState: function () {
      const doneList = this.getDoneList();

      // Decide whether to add the blank state
      let addBlankState = true;

      this.state.lists.forEach(function (list) {
        if (list.type !== 'backlog' && list.type !== 'done') {
          addBlankState = false;
          return;
        }
      });

      if (addBlankState) {
        this.new({
          id: 'blank',
          list_type: 'blank',
          title: 'Welcome to your Issue Board!',
          position: 0
        });
      }
    },
    removeBlankState: function () {
      this.removeList('blank');
    },
    getDoneList: function () {
      return _.find(this.state.lists, (list) => {
        return list.type === 'done';
      });
    },
    removeList: function (id) {
      const list = _.find(this.state.lists, (list) => {
        return list.id === id;
      });

      if (id !== 'blank') {
        list.destroy();
      }

      this.state.lists = _.reject(this.state.lists, (list) => {
        return list.id === id;
      });

      if (id !== 'blank') {
        this.addBlankState();
      }
    },
    moveList: function (oldIndex, newIndex) {
      const listFrom = _.find(this.state.lists, (list) => {
        return list.position === oldIndex;
      });

      const listTo = _.find(this.state.lists, (list) => {
        return list.position === newIndex;
      });

      listFrom.position = newIndex;
      if (newIndex > listTo.position) {
        listTo.position--;
      } else {
        listTo.position++;
      }

      listFrom.update();
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

      // Add to new lists issues if it doesn't already exist
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

      service.moveIssue(issue.id, listFrom.id, listTo.id);
    },
    getListsForIssue: function (issue) {
      return _.filter(this.state.lists, (list) => {
        return list.findIssue(issue.id);
      });
    },
    clearDone: function () {
      Vue.set(BoardsStore.state, 'done', {});
    }
  };
}(window));
