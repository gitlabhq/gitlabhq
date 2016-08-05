class List {
  constructor (obj) {
    this.id = obj.id;
    this.position = obj.position;
    this.title = obj.title;
    this.type = obj.list_type;
    this.issues = [];

    if (obj.label) {
      this.label = new Label(obj.label);
    }

    if (this.type !== 'blank') {
      this.getIssues();
    }
  }

  save () {
    gl.boardService.createList(this.label.id)
      .then((resp) => {
        const data = resp.json();

        this.id = data.id;
        this.type = data.list_type;
        this.position = data.position;
      });
  }

  destroy () {
    if (this.type !== 'blank') {
      gl.boardService.destroyList(this.id);
    }
  }

  update () {
    gl.boardService.updateList(this);
  }

  canSearch () {
    return this.type === 'backlog';
  }

  getIssues (filter = {}) {
    this.loading = true;
    
    gl.boardService.getIssuesForList(this.id, filter)
      .then((resp) => {
        const data = resp.json();
        this.loading = false;

        this.issues = [];
        this.createIssues(data);
      });
  }

  createIssues (data) {
    data.forEach((issue) => {
      this.issues.push(new Issue(issue));
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

  removeIssue (removeIssue, listLabels) {
    this.issues = _.reject(this.issues, (issue) => {
      const matchesRemove = removeIssue.id === issue.id;

      if (matchesRemove) {
        if (typeof listLabels !== 'undefined') {
          listLabels.forEach((listLabel) => {
            issue.removeLabel(listLabel);
          });
        } else {
          issue.removeLabel(this.label);
        }
      }

      return matchesRemove;
    });
  }
}
