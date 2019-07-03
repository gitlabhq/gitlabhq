import $ from 'jquery';
import { slugify } from './lib/utils/text_utility';

export default class Group {
  constructor() {
    this.groupPath = $('#group_path');
    this.groupName = $('#group_name');
    this.updateHandler = this.update.bind(this);
    this.resetHandler = this.reset.bind(this);
    if (this.groupName.val() === '') {
      this.groupName.on('keyup', this.updateHandler);
      this.groupPath.on('keydown', this.resetHandler);
    }
  }

  update() {
    const slug = slugify(this.groupName.val());
    this.groupPath.val(slug);
  }

  reset() {
    this.groupName.off('keyup', this.updateHandler);
    this.groupPath.off('keydown', this.resetHandler);
  }
}
