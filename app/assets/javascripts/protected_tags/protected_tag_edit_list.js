import Vue from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import ProtectedTagEdit from './protected_tag_edit.vue';

export default class ProtectedTagEditList {
  constructor(options) {
    this.hasLicense = options.hasLicense;
    this.initEditForm();
  }

  initEditForm() {
    document
      .querySelector('.protected-tags-list')
      .querySelectorAll('.js-protected-tag-edit-form')
      ?.forEach((el) => {
        const accessDropdownEl = el.querySelector('.js-allowed-to-create');
        this.initAccessDropdown(accessDropdownEl, {
          url: el.dataset.url,
          hasLicense: this.hasLicense,
          accessLevelsData: gon.create_access_levels.roles,
        });
      });
  }

  // eslint-disable-next-line class-methods-use-this
  initAccessDropdown(el, options) {
    if (!el) return null;

    let preselected = [];
    try {
      preselected = JSON.parse(el.dataset.preselectedItems);
    } catch (e) {
      Sentry.captureException(e);
    }

    return new Vue({
      el,
      render(createElement) {
        return createElement(ProtectedTagEdit, {
          props: {
            preselectedItems: preselected,
            searchEnabled: el.dataset.filter !== undefined,
            ...options,
          },
        });
      },
    });
  }
}
