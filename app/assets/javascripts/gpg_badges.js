import $ from 'jquery';
import { parseQueryStringIntoObject } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';

export default class GpgBadges {
  static fetch() {
    const badges = $('.js-loading-gpg-badge');
    const form = $('.commits-search-form');

    badges.html('<i class="fa fa-spinner fa-spin"></i>');

    const params = parseQueryStringIntoObject(form.serialize());
    return axios.get(form.data('signaturesPath'), { params })
    .then(({ data }) => {
      data.signatures.forEach((signature) => {
        badges.filter(`[data-commit-sha="${signature.commit_sha}"]`).replaceWith(signature.html);
      });
    })
    .catch(() => flash(__('An error occurred while loading commits')));
  }
}
