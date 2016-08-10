class List {
  constructor (obj) {
    this.id = obj.id;
    this.position = obj.position;
    this.title = obj.title;
    this.type = obj.list_type;
    this.filters = BoardsStore.state.filters;
    this.page = 1;
    this.loading = true;
    this.issues = [];

    if (obj.label) {
      this.label = new ListLabel(obj.label);
    }

    if (this.type !== 'blank' && this.id) {
      this.getIssues();
    }
  }

  save () {
    return gl.boardService.createList(this.label.id)
      .then((resp) => {
        const data = resp.json();

        this.id = data.id;
        this.type = data.list_type;
        this.position = data.position;

        return this.getIssues();
      });
  }

  destroy () {
    if (this.type !== 'blank') {
      BoardsStore.state.lists = _.reject(BoardsStore.state.lists, (list) => {
        return list.id === this.id;
      });
      BoardsStore.updateNewListDropdown();

      gl.boardService.destroyList(this.id);
    }
  }

  update () {
    gl.boardService.updateList(this);
  }

  nextPage () {
    if (this.issues.length / 20 === this.page) {
      this.page++;

      return this.getIssues(false);
    }
  }

  canSearch () {
    return this.type === 'backlog';
  }

  getIssues (emptyIssues = true) {
    let data = _.extend({ page: this.page }, this.filters);

    if (this.label) {
      data.label_name = _.reject(data.label_name, (label) => {
        return label === this.label.title;
      });
    }

    if (emptyIssues) {
      this.loading = true;
    }

    return gl.boardService.getIssuesForList(this.id, data)
      .then((resp) => {
        const data = resp.json();
        this.loading = false;

        if (emptyIssues) {
          this.issues = [];
        }

        this.createIssues(data);
      });
  }

  createIssues (data) {
    _.each(data, (issueObj) => {
      this.issues.push(new ListIssue(issueObj));
    });
  }

  addIssue (issue, listFrom) {
    this.issues.push(issue);

    issue.addLabel(this.label);

    gl.boardService.moveIssue(issue.id, listFrom.id, this.id);
  }

  findIssue (id) {
    return _.find(this.issues, (issue) => {
      return issue.id === id;
    });
  }

  removeIssue (removeIssue) {
    this.issues = _.reject(this.issues, (issue) => {
      const matchesRemove = removeIssue.id === issue.id;

      if (matchesRemove) {
        issue.removeLabel(this.label);
      }

      return matchesRemove;
    });
  }
}
