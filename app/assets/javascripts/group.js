import $ from 'jquery';

export default class Group {
  constructor() {
    this.groupPath = $('#group_path');
    this.groupName = $('#group_name');
    this.updateHandler = this.update.bind(this);
    this.resetHandler = this.reset.bind(this);
    if (this.groupName.val() === '') {
      this.groupPath.on('keyup', this.updateHandler);
      this.groupName.on('keydown', this.resetHandler);
    }
  }

  update() {
    this.groupName.val(this.groupPath.val());
  }

  reset() {
    this.groupPath.off('keyup', this.updateHandler);
    this.groupName.off('keydown', this.resetHandler);
  }
}
