import { createAlert } from '~/alert';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';

import { __ } from '~/locale';

export default class GpgBadges {
  static fetch() {
    const tag = document.querySelector('.js-signature-container');
    if (!tag) {
      return Promise.resolve();
    }

    const badges = document.querySelectorAll('.js-loading-signature-badge');

    badges.forEach((badge) => {
      badge.replaceChildren(loadingIconForLegacyJS());
      Array.from(badge.children).forEach((child) =>
        child.setAttribute('aria-label', __('Loading')),
      );
    });

    const displayError = () =>
      createAlert({
        message: __('An error occurred while loading commit signatures'),
      });

    const endpoint = tag.dataset.signaturesPath;
    if (!endpoint) {
      displayError();
      return Promise.reject(new Error(__('Missing commit signatures endpoint!')));
    }

    const params = tag instanceof HTMLFormElement ? Object.fromEntries(new FormData(tag)) : {};
    return axios
      .get(endpoint, { params })
      .then(({ data }) => {
        data.signatures.forEach((signature) => {
          const template = document.createElement('template');
          template.innerHTML = sanitize(signature.html);
          badges.forEach((badge) => {
            if (badge.dataset.commitSha === signature.commit_sha) {
              badge.replaceWith(template.content.cloneNode(true));
            }
          });
        });
      })
      .catch(displayError);
  }
}
