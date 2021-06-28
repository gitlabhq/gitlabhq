import createFlash from '~/flash';
import { __ } from '~/locale';
import fetchGroupPathAvailability from '~/pages/groups/new/fetch_group_path_availability';
import { slugify } from './lib/utils/text_utility';

export default class Group {
  constructor() {
    this.groupPaths = Array.from(document.querySelectorAll('.js-autofill-group-path'));
    this.groupNames = Array.from(document.querySelectorAll('.js-autofill-group-name'));
    this.parentId = document.getElementById('group_parent_id');
    this.updateHandler = this.update.bind(this);
    this.resetHandler = this.reset.bind(this);
    this.updateGroupPathSlugHandler = this.updateGroupPathSlug.bind(this);

    this.groupNames.forEach((groupName) => {
      if (groupName.value === '') {
        groupName.addEventListener('keyup', this.updateHandler);

        groupName.addEventListener('keyup', this.updateGroupPathSlugHandler);
      }
    });

    this.groupPaths.forEach((groupPath) => {
      groupPath.addEventListener('keydown', this.resetHandler);
    });
  }

  update({ currentTarget: { value: updatedValue } }) {
    const slug = slugify(updatedValue);

    this.groupNames.forEach((element) => {
      element.value = updatedValue;
    });
    this.groupPaths.forEach((element) => {
      element.value = slug;
    });
  }

  reset() {
    this.groupNames.forEach((groupName) => {
      groupName.removeEventListener('keyup', this.updateHandler);
      groupName.removeEventListener('blur', this.checkPathHandler);
    });

    this.groupPaths.forEach((groupPath) => {
      groupPath.removeEventListener('keydown', this.resetHandler);
    });
  }

  updateGroupPathSlug({ currentTarget: { value } = '' } = {}) {
    const slug = this.groupPaths[0]?.value || slugify(value);
    if (!slug) return;

    fetchGroupPathAvailability(slug, this.parentId?.value)
      .then(({ data }) => data)
      .then(({ exists, suggests }) => {
        if (exists && suggests.length) {
          const [suggestedSlug] = suggests;

          this.groupPaths.forEach((element) => {
            element.value = suggestedSlug;
          });
        } else if (exists && !suggests.length) {
          createFlash({
            message: __('Unable to suggest a path. Please refresh and try again.'),
          });
        }
      })
      .catch(() =>
        createFlash({
          message: __('An error occurred while checking group path. Please refresh and try again.'),
        }),
      );
  }
}
