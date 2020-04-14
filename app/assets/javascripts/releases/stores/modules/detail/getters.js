import { isEmpty } from 'lodash';
import { hasContent } from '~/lib/utils/text_utility';

/**
 * @param {Object} link The link to test
 * @returns {Boolean} `true` if the release link is empty, i.e. it has
 * empty (or whitespace-only) values for both `url` and `name`.
 * Otherwise, `false`.
 */
const isEmptyReleaseLink = link => !hasContent(link.url) && !hasContent(link.name);

/** Returns all release links that aren't empty */
export const releaseLinksToCreate = state => {
  if (!state.release) {
    return [];
  }

  return state.release.assets.links.filter(l => !isEmptyReleaseLink(l));
};

/** Returns all release links that should be deleted */
export const releaseLinksToDelete = state => {
  if (!state.originalRelease) {
    return [];
  }

  return state.originalRelease.assets.links;
};

/** Returns all validation errors on the release object */
export const validationErrors = state => {
  const errors = {
    assets: {
      links: {},
    },
  };

  if (!state.release) {
    return errors;
  }

  // Each key of this object is a URL, and the value is an
  // array of Release link objects that share this URL.
  // This is used for detecting duplicate URLs.
  const urlToLinksMap = new Map();

  state.release.assets.links.forEach(link => {
    errors.assets.links[link.id] = {};

    // Only validate non-empty URLs
    if (isEmptyReleaseLink(link)) {
      return;
    }

    if (!hasContent(link.url)) {
      errors.assets.links[link.id].isUrlEmpty = true;
    }

    if (!hasContent(link.name)) {
      errors.assets.links[link.id].isNameEmpty = true;
    }

    const normalizedUrl = link.url.trim().toLowerCase();

    // Compare each URL to every other URL and flag any duplicates
    if (urlToLinksMap.has(normalizedUrl)) {
      // a duplicate URL was found!

      // add a validation error for each link that shares this URL
      const duplicates = urlToLinksMap.get(normalizedUrl);
      duplicates.push(link);
      duplicates.forEach(duplicateLink => {
        errors.assets.links[duplicateLink.id].isDuplicate = true;
      });
    } else {
      // no duplicate URL was found

      urlToLinksMap.set(normalizedUrl, [link]);
    }

    if (!/^(http|https|ftp):\/\//.test(normalizedUrl)) {
      errors.assets.links[link.id].isBadFormat = true;
    }
  });

  return errors;
};

/** Returns whether or not the release object is valid */
export const isValid = (_state, getters) => {
  return Object.values(getters.validationErrors.assets.links).every(isEmpty);
};
