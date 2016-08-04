class Issue {
  constructor (obj) {
    this.id = obj.iid;
    this.title = obj.title;
    this.labels = [];

    obj.labels.forEach((label) => {
      this.labels.push(new Label(label));
    });
  }

  addLabel (label) {
    if (label) {
      const hasLabel = this.findLabel(label);

      if (!hasLabel) {
        this.labels.push(new Label(label));
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
}
