((w) => {
  w.BoardsStore = {
    state: {},
    create: function () {
      this.state.lists = [];
      this.state.filters = {
        author_id: gl.utils.getParameterValues('author_id')[0],
        assignee_id: gl.utils.getParameterValues('assignee_id')[0],
        milestone_title: gl.utils.getParameterValues('milestone_title')[0],
        label_name: gl.utils.getParameterValues('label_name[]')
      };
    },
    new: function (board, persist = true) {
      const doneList = this.getDoneList(),
            list = new List(board);
      this.state.lists.push(list);

      if (persist) {
        list.save();
        this.removeBlankState();
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
      const addBlankState = this.shouldAddBlankState();

      if (this.welcomeIsHidden()) return;

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
      if (this.welcomeIsHidden()) return;

      this.removeList('blank');

      $.cookie('issue_board_welcome_hidden', 'true', {
        expires: 365 * 10
      });
    },
    welcomeIsHidden: function () {
      return $.cookie('issue_board_welcome_hidden') === 'true';
    },
    getDoneList: function () {
      return this.findList('type', 'done');
    },
    removeList: function (id) {
      const list = this.findList('id', id);

      if (!list) return;

      list.destroy();

      this.state.lists = _.reject(this.state.lists, (list) => {
        return list.id === id;
      });
    },
    moveList: function (oldIndex, newIndex) {
      const listFrom = this.findList('position', oldIndex),
            listTo = this.findList('position', newIndex);

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
      const issueLists = issue.getLists(),
            listLabels = issueLists.map(function (issue) {
              return issue.label;
            });

      listFrom.removeIssue(issue);

      // Add to new lists issues if it doesn't already exist
      if (!issueTo) {
        listTo.addIssue(issue, listFrom);
      }

      if (listTo.type === 'done' && listFrom.type !== 'backlog') {
        issueLists.forEach((list) => {
          list.removeIssue(issue);
        });
        issue.removeLabels(listLabels);
      }
    },
    findList: function (key, val) {
      return _.find(this.state.lists, (list) => {
        return list[key] === val;
      });
    },
    updateFiltersUrl: function () {
      history.pushState(null, null, `?${$.param(this.state.filters)}`);
    }
  };
}(window));
