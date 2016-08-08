((w) => {
  w.BoardsStore = {
    disabled: false,
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
    addList: function (listObj) {
      const list = new List(listObj);
      this.state.lists.push(list);

      return list;
    },
    new: function (listObj) {
      const list = this.addList(listObj),
            backlogList = this.findList('type', 'backlog');

      list
        .save()
        .then(function () {
          // Remove any new issues from the backlog
          // as they will be visible in the new list
          _.each(list.issues, backlogList.removeIssue.bind(backlogList));
        });
      this.removeBlankState();
    },
    updateNewListDropdown: function () {
      const data = $('.js-new-board-list').data('glDropdown').renderedData;

      if (data) {
        $('.js-new-board-list').data('glDropdown').renderData(data);
      }
    },
    shouldAddBlankState: function () {
      // Decide whether to add the blank state
      return !_.find(this.state.lists, function (list) {
        return list.type === 'backlog' || list.type === 'done';
      });
    },
    addBlankState: function () {
      if (this.welcomeIsHidden() || this.disabled) return;

      if (this.shouldAddBlankState()) {
        this.addList({
          id: 'blank',
          list_type: 'blank',
          title: 'Welcome to your Issue Board!',
          position: 0
        });
      }
    },
    removeBlankState: function () {
      this.removeList('blank');

      $.cookie('issue_board_welcome_hidden', 'true', {
        expires: 365 * 10
      });
    },
    welcomeIsHidden: function () {
      return $.cookie('issue_board_welcome_hidden') === 'true';
    },
    removeList: function (id) {
      const list = this.findList('id', id);

      if (!list) return;

      this.state.lists = _.reject(this.state.lists, (list) => {
        return list.id === id;
      });
    },
    moveList: function (oldIndex, newIndex) {
      if (oldIndex === newIndex) return;

      const listFrom = this.findList('position', oldIndex),
            listTo = this.findList('position', newIndex);

      listFrom.position = newIndex;
      if (newIndex === listTo.position) {
        listTo.position = oldIndex;
      } else if (newIndex > listTo.position) {
        listTo.position--;
      } else {
        listTo.position++;
      }

      listFrom.update();
    },
    moveCardToList: function (listFromId, listToId, issueId) {
      const listFrom = this.findList('id', listFromId),
            listTo = this.findList('id', listToId),
            issueTo = listTo.findIssue(issueId),
            issue = listFrom.findIssue(issueId),
            issueLists = issue.getLists(),
            listLabels = issueLists.map(function (issue) {
              return issue.label;
            });

      // Add to new lists issues if it doesn't already exist
      if (!issueTo) {
        listTo.addIssue(issue, listFrom);
      }

      if (listTo.type === 'done' && listFrom.type !== 'backlog') {
        _.each(issueLists, function (list) {
          list.removeIssue(issue);
        });
        issue.removeLabels(listLabels);
      } else {
        listFrom.removeIssue(issue);
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
