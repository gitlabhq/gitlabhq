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
      this.loading = true;
      service.getIssuesForList(this.id)
        .then((resp) => {
          const data = resp.json();
          this.loading = false;

          data.forEach((issue) => {
            this.issues.push(new Issue(issue));
          });
        });
    }
  }

  save () {
    service.createList(this.label.id)
      .then((resp) => {
        const data = resp.json();

        this.id = data.id;
        this.type = data.list_type;
        this.position = data.position;
      });
  }

  destroy () {
    service.destroyList(this.id);
  }

  update () {
    service.updateList(this);
  }

  canSearch () {
    return this.type === 'backlog';
  }

  addIssue (issue, listFrom) {
    this.issues.push(issue);

    issue.addLabel(this.label);

    service.moveIssue(issue.id, listFrom.id, this.id);
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
