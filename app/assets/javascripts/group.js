import { debounce } from 'lodash';

import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { getGroupPathAvailability } from '~/rest_api';
import axios from '~/lib/utils/axios_utils';
import { slugify } from './lib/utils/text_utility';

const DEBOUNCE_TIMEOUT_DURATION = 1000;

export default class Group {
  constructor() {
    this.groupPaths = Array.from(document.querySelectorAll('.js-autofill-group-path'));
    this.groupNames = Array.from(document.querySelectorAll('.js-autofill-group-name'));
    this.parentId = document.getElementById('group_parent_id');
    this.updateHandler = this.update.bind(this);
    this.resetHandler = this.reset.bind(this);
    this.updateGroupPathSlugHandler = debounce(
      this.updateGroupPathSlug.bind(this),
      DEBOUNCE_TIMEOUT_DURATION,
    );
    this.currentApiRequestController = null;

    this.groupNames.forEach((groupName) => {
      groupName.addEventListener('keyup', this.updateHandler);
      groupName.addEventListener('keyup', this.updateGroupPathSlugHandler);
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

  updateGroupPathSlug({ target: { value } = '' } = {}) {
    if (this.currentApiRequestController !== null) {
      this.currentApiRequestController.abort();
    }

    this.currentApiRequestController = new AbortController();

    const slug = slugify(value);
    if (!slug) return;

    getGroupPathAvailability(slug, this.parentId?.value, {
      signal: this.currentApiRequestController.signal,
    })
      .then(({ data }) => data)
      .then(({ exists, suggests }) => {
        this.currentApiRequestController = null;

        if (exists && suggests.length) {
          const [suggestedSlug] = suggests;

          this.groupPaths.forEach((element) => {
            element.value = suggestedSlug;
          });
        } else if (exists && !suggests.length) {
          createAlert({
            message: __('Unable to suggest a path. Please refresh and try again.'),
          });
        }
      })
      .catch((error) => {
        if (axios.isCancel(error)) {
          return;
        }

        createAlert({
          message: __('An error occurred while checking group path. Please refresh and try again.'),
        });
      });
  }
}
