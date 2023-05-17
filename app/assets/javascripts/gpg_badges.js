import $ from 'jquery';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';

import { __ } from '~/locale';

export default class GpgBadges {
  static fetch() {
    const tag = $('.js-signature-container');
    if (tag.length === 0) {
      return Promise.resolve();
    }

    const badges = $('.js-loading-signature-badge');

    badges.html(loadingIconForLegacyJS());
    badges.children().attr('aria-label', __('Loading'));

    const displayError = () =>
      createAlert({
        message: __('An error occurred while loading commit signatures'),
      });

    const endpoint = tag.data('signaturesPath');
    if (!endpoint) {
      displayError();
      return Promise.reject(new Error(__('Missing commit signatures endpoint!')));
    }

    const params = queryToObject(tag.serialize());
    return axios
      .get(endpoint, { params })
      .then(({ data }) => {
        data.signatures.forEach((signature) => {
          badges.filter(`[data-commit-sha="${signature.commit_sha}"]`).replaceWith(signature.html);
        });
      })
      .catch(displayError);
  }
}
