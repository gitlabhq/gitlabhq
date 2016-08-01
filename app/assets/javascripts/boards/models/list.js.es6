class List {
  constructor (obj) {
    this.id = obj.id;
    this.index = obj.index;
    this.search = obj.search || false;
    this.title = obj.title;

    if (obj.label) {
      this.label = new Label(obj.label);
    }

    if (obj.issues) {
      this.issues = [];
      obj.issues.forEach((issue) => {
        this.issues.push(new Issue(issue));
      });
    }
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
