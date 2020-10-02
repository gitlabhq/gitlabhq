import { redirectTo, getBaseURL, stripFinalUrlSegment } from '~/lib/utils/url_utility';
import { initRemoveTag } from '../remove_tag';

document.addEventListener('DOMContentLoaded', () => {
  initRemoveTag({
    onDelete: (path = '') => {
      redirectTo(stripFinalUrlSegment([getBaseURL(), path].join('')));
    },
  });
});
