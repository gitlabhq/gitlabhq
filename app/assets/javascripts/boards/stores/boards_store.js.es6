(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardsStore = {
    disabled: false,
    state: {},
    create () {
      this.state.lists = [];
      this.state.filters = {
        author_id: gl.utils.getParameterValues('author_id')[0],
        assignee_id: gl.utils.getParameterValues('assignee_id')[0],
        milestone_title: gl.utils.getParameterValues('milestone_title')[0],
        label_name: gl.utils.getParameterValues('label_name[]')
      };
    },
    addList (listObj) {
      const list = new List(listObj);
      this.state.lists.push(list);

      return list;
    },
    new (listObj) {
      const list = this.addList(listObj),
            backlogList = this.findList('type', 'backlog', 'backlog');

      list
        .save()
        .then(() => {
          // Remove any new issues from the backlog
          // as they will be visible in the new list
          for (let i = 0, issuesLength = list.issues.length; i < issuesLength; i++) {
            const issue = list.issues[i];
            backlogList.removeIssue(issue);
          }
        });
      this.removeBlankState();
    },
    updateNewListDropdown (listId) {
      $(`.js-board-list-${listId}`).removeClass('is-active');
    },
    shouldAddBlankState () {
      // Decide whether to add the blank state
      return !(this.state.lists.filter((list) => {
        return list.type !== 'backlog' && list.type !== 'done';
      })[0]);
    },
    addBlankState () {
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
    removeBlankState () {
      this.removeList('blank');

      $.cookie('issue_board_welcome_hidden', 'true', {
        expires: 365 * 10
      });
    },
    welcomeIsHidden () {
      return $.cookie('issue_board_welcome_hidden') === 'true';
    },
    removeList (id) {
      const list = this.findList('id', id, 'blank');

      if (!list) return;

      this.state.lists = this.state.lists.filter((list) => {
        return list.id !== id;
      });
    },
    moveList (oldIndex, newIndex) {
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
    moveCardToList (listFromId, listToId, issueId) {
      const listFrom = this.findList('id', listFromId, false),
            listTo = this.findList('id', listToId, false),
            issueTo = listTo.findIssue(issueId),
            issue = listFrom.findIssue(issueId),
            issueLists = issue.getLists(),
            listLabels = issueLists.map((issue) => {
              return issue.label;
            });

      // Add to new lists issues if it doesn't already exist
      if (!issueTo) {
        listTo.addIssue(issue, listFrom);
      }

      if (listTo.type === 'done' && listFrom.type !== 'backlog') {
        for (let i = 0, listsLength = issueLists.length; i < listsLength; i++) {
          const list = issueLists[i];
          list.removeIssue(issue);
        }
        issue.removeLabels(listLabels);
      } else {
        listFrom.removeIssue(issue);
      }
    },
    findList (key, val, type = 'label') {
      return this.state.lists.filter((list) => {
        const byType = type ? list['type'] === type : true;

        return list[key] === val && byType;
      })[0];
    },
    updateFiltersUrl () {
      history.pushState(null, null, `?${$.param(this.state.filters)}`);
    }
  };
})();
