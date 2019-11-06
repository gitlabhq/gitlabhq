import $ from 'jquery';
import { slugify } from './lib/utils/text_utility';
import fetchGroupPathAvailability from '~/pages/groups/new/fetch_group_path_availability';
import flash from '~/flash';
import { __ } from '~/locale';

export default class Group {
  constructor() {
    this.groupPath = $('#group_path');
    this.groupName = $('#group_name');
    this.parentId = $('#group_parent_id');
    this.updateHandler = this.update.bind(this);
    this.resetHandler = this.reset.bind(this);
    this.updateGroupPathSlugHandler = this.updateGroupPathSlug.bind(this);
    if (this.groupName.val() === '') {
      this.groupName.on('keyup', this.updateHandler);
      this.groupPath.on('keydown', this.resetHandler);
      if (!this.parentId.val()) {
        this.groupName.on('blur', this.updateGroupPathSlugHandler);
      }
    }
  }

  update() {
    const slug = slugify(this.groupName.val());
    this.groupPath.val(slug);
  }

  reset() {
    this.groupName.off('keyup', this.updateHandler);
    this.groupPath.off('keydown', this.resetHandler);
    this.groupName.off('blur', this.checkPathHandler);
  }

  updateGroupPathSlug() {
    const slug = this.groupPath.val() || slugify(this.groupName.val());
    if (!slug) return;

    fetchGroupPathAvailability(slug)
      .then(({ data }) => data)
      .then(data => {
        if (data.exists && data.suggests.length > 0) {
          const suggestedSlug = data.suggests[0];
          this.groupPath.val(suggestedSlug);
        }
      })
      .catch(() => flash(__('An error occurred while checking group path')));
  }
}
