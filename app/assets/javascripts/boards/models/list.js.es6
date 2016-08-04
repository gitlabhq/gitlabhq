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

  destroy () {
    service.destroyList(this.id);
  }

  update () {
    service.updateList(this);
  }

  canSearch () {
    return this.type === 'backlog';
  }

  addIssue (issue, index) {
    this.issues.splice(index, 0, issue);

    issue.addLabel(this.label);
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
