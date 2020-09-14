import $ from 'jquery';
import { parseQueryStringIntoObject } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __ } from '~/locale';

export default class GpgBadges {
  static fetch() {
    const tag = $('.js-signature-container');
    if (tag.length === 0) {
      return Promise.resolve();
    }

    const badges = $('.js-loading-gpg-badge');

    badges.html('<span class="gl-spinner gl-spinner-orange gl-spinner-sm"></span>');
    badges.children().attr('aria-label', __('Loading'));

    const displayError = () => createFlash(__('An error occurred while loading commit signatures'));

    const endpoint = tag.data('signaturesPath');
    if (!endpoint) {
      displayError();
      return Promise.reject(new Error(__('Missing commit signatures endpoint!')));
    }

    const params = parseQueryStringIntoObject(tag.serialize());
    return axios
      .get(endpoint, { params })
      .then(({ data }) => {
        data.signatures.forEach(signature => {
          badges.filter(`[data-commit-sha="${signature.commit_sha}"]`).replaceWith(signature.html);
        });
      })
      .catch(displayError);
  }
}
