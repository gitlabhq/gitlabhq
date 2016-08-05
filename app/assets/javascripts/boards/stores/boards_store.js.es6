((w) => {
  w.BoardsStore = {
    state: {
      lists: [],
      filters: {
        author_id: null,
        assignee_id: null,
        milestone_title: null,
        label_name: []
      }
    },
    reset: function () {
      this.state.lists = [];
      this.state.filters = {
        author: {},
        assignee: {},
        milestone: {},
        label: []
      };
    },
    new: function (board, persist = true) {
      const doneList = this.getDoneList(),
            list = new List(board);
      this.state.lists.push(list);

      if (persist) {
        list.save();
        this.removeBlankState();
        this.addBlankState();
      }

      return list;
    },
    shouldAddBlankState: function () {
      // Decide whether to add the blank state
      let addBlankState = true;

      this.state.lists.forEach(function (list) {
        if (list.type !== 'backlog' && list.type !== 'done') {
          addBlankState = false;
          return;
        }
      });
      return addBlankState;
    },
    addBlankState: function () {
      if ($.cookie('issue_board_welcome_hidden') === 'true') return;

      const doneList = this.getDoneList(),
            addBlankState = this.shouldAddBlankState();

      if (addBlankState) {
        this.new({
          id: 'blank',
          list_type: 'blank',
          title: 'Welcome to your Issue Board!',
          position: 0
        }, false);
      }
    },
    removeBlankState: function () {
      if ($.cookie('issue_board_welcome_hidden') === 'true') return;
      this.removeList('blank');

      $.cookie('issue_board_welcome_hidden', 'true', {
        expires: 365 * 10
      });
    },
    getDoneList: function () {
      return this.findList('type', 'done');
    },
    removeList: function (id) {
      const list = this.findList('id', id);
      list.destroy();

      this.state.lists = _.reject(this.state.lists, (list) => {
        return list.id === id;
      });
    },
    moveList: function (oldIndex, newIndex) {
      const listFrom = this.findList('position', oldIndex),
            istTo = this.findList('position', newIndex);

      listFrom.position = newIndex;
      if (newIndex > listTo.position) {
        listTo.position--;
      } else {
        listTo.position++;
      }

      listFrom.update();
    },
    moveCardToList: function (listFromId, listToId, issueId) {
      const listFrom = this.findList('id', listFromId),
            listTo = this.findList('id', listToId),
            issueTo = listTo.findIssue(issueId);
      let issue = listFrom.findIssue(issueId);
      const issueLists = issue.getLists();
      listFrom.removeIssue(issue);

      // Add to new lists issues if it doesn't already exist
      if (issueTo) {
        listTo.removeIssue(issueTo);
      } else {
        listTo.addIssue(issue, listFrom);
      }

      if (listTo.type === 'done' && listFrom.type !== 'backlog') {
        issueLists.forEach((list) => {
          list.removeIssue(issue);
        });
      }
    },
    findList: function (key, val) {
      return _.find(this.state.lists, (list) => {
        return list[key] === val;
      });
    }
  };
}(window));
