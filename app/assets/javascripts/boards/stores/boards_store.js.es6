(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardsStore = {
    disabled: false,
    state: {},
    moving: {
      issue: {},
      list: {}
    },
    create () {
      this.state.lists = [];
      this.state.filters = {
        author_id: gl.utils.getParameterValues('author_id')[0],
        assignee_id: gl.utils.getParameterValues('assignee_id')[0],
        milestone_title: gl.utils.getParameterValues('milestone_title')[0],
        label_name: gl.utils.getParameterValues('label_name[]'),
        search: ''
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
          list.issues.forEach(backlogList.removeIssue.bind(backlogList));
        });
      this.removeBlankState();
    },
    updateNewListDropdown (listId) {
      $(`.js-board-list-${listId}`).removeClass('is-active');
    },
    shouldAddBlankState () {
      // Decide whether to add the blank state
      return !(this.state.lists.filter( list => list.type !== 'backlog' && list.type !== 'done' )[0]);
    },
    addBlankState () {
      if (!this.shouldAddBlankState() || this.welcomeIsHidden() || this.disabled) return;

      this.addList({
        id: 'blank',
        list_type: 'blank',
        title: 'Welcome to your Issue Board!',
        position: 0
      });
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
    removeList (id, type = 'blank') {
      const list = this.findList('id', id, type);

      if (!list) return;

      this.state.lists = this.state.lists.filter( list => list.id !== id );
    },
    moveList (listFrom, orderLists) {
      orderLists.forEach((id, i) => {
        const list = this.findList('id', parseInt(id));

        list.position = i;
      });
      listFrom.update();
    },
    moveIssueToList (listFrom, listTo, issue) {
      const issueTo = listTo.findIssue(issue.id),
            issueLists = issue.getLists(),
            listLabels = issueLists.map( listIssue => listIssue.label );

      // Add to new lists issues if it doesn't already exist
      if (!issueTo) {
        listTo.addIssue(issue, listFrom);
      }

      if (listTo.type === 'done' && listFrom.type !== 'backlog') {
        issueLists.forEach((list) => {
          list.removeIssue(issue);
        })
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
