class ListIssue {
  constructor (obj) {
    this.id = obj.iid;
    this.title = obj.title;
    this.confidential = obj.confidential;

    if (obj.assignee) {
      this.assignee = new ListUser(obj.assignee);
    }

    this.labels = [];

    _.each(obj.labels, (label) => {
      this.labels.push(new ListLabel(label));
    });

    this.priority = _.reduce(this.labels, (max, label) => {
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
    return _.find(this.labels, (label) => {
      return label.title === findLabel.title;
    });
  }

  removeLabel (removeLabel) {
    if (removeLabel) {
      this.labels = _.reject(this.labels, (label) => {
        return removeLabel.title === label.title;
      });
    }
  }

  removeLabels (labels) {
    _.each(labels, this.removeLabel.bind(this));
  }

  getLists () {
    return _.filter(BoardsStore.state.lists, (list) => {
      return list.findIssue(this.id);
    });
  }
}
