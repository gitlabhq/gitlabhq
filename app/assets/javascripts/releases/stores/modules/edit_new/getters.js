import { isEmpty } from 'lodash';
import { hasContent } from '~/lib/utils/text_utility';

/**
 * @returns {Boolean} `true` if the app is editing an existing release.
 * `false` if the app is creating a new release.
 */
export const isExistingRelease = (state) => {
  return Boolean(state.tagName);
};

/**
 * @param {Object} link The link to test
 * @returns {Boolean} `true` if the release link is empty, i.e. it has
 * empty (or whitespace-only) values for both `url` and `name`.
 * Otherwise, `false`.
 */
const isEmptyReleaseLink = (link) => !hasContent(link.url) && !hasContent(link.name);

/** Returns all release links that aren't empty */
export const releaseLinksToCreate = (state) => {
  if (!state.release) {
    return [];
  }

  return state.release.assets.links.filter((l) => !isEmptyReleaseLink(l));
};

/** Returns all release links that should be deleted */
export const releaseLinksToDelete = (state) => {
  if (!state.originalRelease) {
    return [];
  }

  return state.originalRelease.assets.links;
};

/** Returns all validation errors on the release object */
export const validationErrors = (state) => {
  const errors = {
    assets: {
      links: {},
    },
  };

  if (!state.release) {
    return errors;
  }

  if (!state.release.tagName?.trim?.().length) {
    errors.isTagNameEmpty = true;
  }

  // Each key of this object is a URL, and the value is an
  // array of Release link objects that share this URL.
  // This is used for detecting duplicate URLs.
  const urlToLinksMap = new Map();

  state.release.assets.links.forEach((link) => {
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
      duplicates.forEach((duplicateLink) => {
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
  const errors = getters.validationErrors;
  return Object.values(errors.assets.links).every(isEmpty) && !errors.isTagNameEmpty;
};

/** Returns all the variables for a `releaseUpdate` GraphQL mutation */
export const releaseUpdateMutatationVariables = (state) => {
  const name = state.release.name?.trim().length > 0 ? state.release.name.trim() : null;

  // Milestones may be either a list of milestone objects OR just a list
  // of milestone titles. The GraphQL mutation requires only the titles be sent.
  const milestones = (state.release.milestones || []).map((m) => m.title || m);

  return {
    input: {
      projectPath: state.projectPath,
      tagName: state.release.tagName,
      name,
      description: state.release.description,
      milestones,
    },
  };
};

/** Returns all the variables for a `releaseCreate` GraphQL mutation */
export const releaseCreateMutatationVariables = (state, getters) => {
  return {
    input: {
      ...getters.releaseUpdateMutatationVariables.input,
      ref: state.createFrom,
      assets: {
        links: getters.releaseLinksToCreate.map(({ name, url, linkType }) => ({
          name,
          url,
          linkType: linkType.toUpperCase(),
        })),
      },
    },
  };
};
