import $ from 'jquery';
import { parseQueryStringIntoObject } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __ } from '~/locale';

export default class GpgBadges {
  static fetch() {
    const tag = $('.js-signature-container');
    if (tag.length === 0) {
      return Promise.resolve();
    }

    const badges = $('.js-loading-gpg-badge');

    badges.html('<i class="fa fa-spinner fa-spin"></i>');

    const displayError = () => createFlash(__('An error occurred while loading commit signatures'));

    const endpoint = tag.data('signaturesPath');
    if (!endpoint) {
      displayError();
      return Promise.reject(new Error('Missing commit signatures endpoint!'));
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
