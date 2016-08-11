class ListIssue {
  constructor (obj) {
    this.id = obj.iid;
    this.title = obj.title;
    this.confidential = obj.confidential;

    if (obj.assignee) {
      this.assignee = new ListUser(obj.assignee);
    }

    this.labels = [];

    for (let i = 0, objLabelsLength = obj.labels.length; i < objLabelsLength; i++) {
      const label = obj.labels[i];
      this.labels.push(new ListLabel(label));
    }

    this.priority = this.labels.reduce((max, label) => {
      return (label.priority < max) ? label.priority : max;
    }, Infinity);
  }

  addLabel (label) {
    if (label) {
      const hasLabel = this.findLabel(label);

      if (!hasLabel) {
        this.labels.push(new ListLabel(label));
      }
    }
  }

  findLabel (findLabel) {
    return this.labels.filter((label) => {
      return label.title === findLabel.title;
    })[0];
  }

  removeLabel (removeLabel) {
    if (removeLabel) {
      this.labels = this.labels.filter((label) => {
        return removeLabel.title !== label.title;
      });
    }
  }

  removeLabels (labels) {
    for (let i = 0, labelsLength = labels.length; i < labelsLength; i++) {
      const label = labels[i];
      this.removeLabel(label);
    }
  }

  getLists () {
    return BoardsStore.state.lists.filter((list) => {
      return list.findIssue(this.id);
    });
  }
}
