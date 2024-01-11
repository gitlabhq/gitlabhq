import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import { hasContent } from '~/lib/utils/text_utility';
import { getDuplicateItemsFromArray } from '~/lib/utils/array_utility';
import { validateTag, ValidationResult } from '~/lib/utils/ref_validator';
import { i18n } from '~/releases/constants';
import { SEARCH, CREATE, EXISTING_TAG, NEW_TAG } from './constants';

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
    tagNameValidation: new ValidationResult(),
  };

  if (!state.release) {
    return errors;
  }

  if (!state.release.tagName || typeof state.release.tagName !== 'string') {
    errors.tagNameValidation.addValidationError(i18n.tagNameIsRequiredMessage);
  } else {
    errors.tagNameValidation = validateTag(state.release.tagName);
  }

  if (state.existingRelease) {
    errors.tagNameValidation.addValidationError(i18n.tagIsAlredyInUseMessage);
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

  // check for duplicated Link Titles
  const linkTitles = state.release.assets.links.map((link) => link.name.trim());
  const duplicatedTitles = getDuplicateItemsFromArray(linkTitles);

  // add a validation error for each link that shares Link Title
  state.release.assets.links.forEach((link) => {
    if (hasContent(link.name) && duplicatedTitles.includes(link.name.trim())) {
      errors.assets.links[link.id].isTitleDuplicate = true;
    }
  });

  return errors;
};

/** Returns whether or not the release object is valid */
export const isValid = (_state, getters) => {
  const errors = getters.validationErrors;
  return (
    Object.values(errors.assets.links).every(isEmpty) &&
    !errors.isTagNameEmpty &&
    !errors.existingRelease
  );
};

/** Returns all the variables for a `releaseUpdate` GraphQL mutation */
export const releaseUpdateMutatationVariables = (state, getters) => {
  const name = state.release.name?.trim().length > 0 ? state.release.name.trim() : null;

  // Milestones may be either a list of milestone objects OR just a list
  // of milestone titles. The GraphQL mutation requires only the titles be sent.
  const milestones = (state.release.milestones || []).map((m) => m.title || m);

  return {
    input: {
      projectPath: state.projectPath,
      tagName: state.release.tagName,
      name,
      releasedAt: getters.releasedAtChanged ? state.release.releasedAt : null,
      description: state.includeTagNotes
        ? getters.formattedReleaseNotes
        : state.release.description,
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
      tagMessage: state.release.tagMessage,
      assets: {
        links: getters.releaseLinksToCreate.map(({ name, url, linkType }) => ({
          name: name.trim(),
          url,
          linkType: linkType.toUpperCase(),
        })),
      },
    },
  };
};

export const releaseDeleteMutationVariables = (state) => ({
  input: {
    projectPath: state.projectPath,
    tagName: state.release.tagName,
  },
});

export const formattedReleaseNotes = (
  { includeTagNotes, release: { description, tagMessage }, tagNotes },
  { isNewTag },
) => {
  const notes = isNewTag ? tagMessage : tagNotes;
  return includeTagNotes && notes
    ? `${description}\n\n### ${s__('Releases|Tag message')}\n\n${notes}\n`
    : description;
};

export const releasedAtChanged = ({ originalReleasedAt, release }) =>
  originalReleasedAt !== release.releasedAt;

export const isSearching = ({ step }) => step === SEARCH;
export const isCreating = ({ step }) => step === CREATE;

export const isExistingTag = ({ tagStep }) => tagStep === EXISTING_TAG;
export const isNewTag = ({ tagStep }) => tagStep === NEW_TAG;

export const localStorageKey = ({ projectPath }) => `${projectPath}/release/new`;
export const localStorageCreateFromKey = ({ projectPath }) =>
  `${projectPath}/release/new/createFrom`;
