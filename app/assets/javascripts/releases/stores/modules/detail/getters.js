/**
 * @returns {Boolean} `true` if the release link is empty, i.e. it has
 * empty (or whitespace-only) values for both `url` and `name`.
 * Otherwise, `false`.
 */
const isEmptyReleaseLink = l => !/\S/.test(l.url) && !/\S/.test(l.name);

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
