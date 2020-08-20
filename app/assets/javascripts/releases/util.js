import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';

/**
 * Converts a release object into a JSON object that can sent to the public
 * API to create or update a release.
 * @param {Object} release The release object to convert
 * @param {string} createFrom The ref to create a new tag from, if necessary
 */
export const releaseToApiJson = (release, createFrom = null) => {
  const name = release.name?.trim().length > 0 ? release.name.trim() : null;

  const milestones = release.milestones ? release.milestones.map(milestone => milestone.title) : [];

  return convertObjectPropsToSnakeCase(
    {
      name,
      tagName: release.tagName,
      ref: createFrom,
      description: release.description,
      milestones,
      assets: release.assets,
    },
    { deep: true },
  );
};

/**
 * Converts a JSON release object returned by the Release API
 * into the structure this Vue application can work with.
 * @param {Object} json The JSON object received from the release API
 */
export const apiJsonToRelease = json => {
  const release = convertObjectPropsToCamelCase(json, { deep: true });

  release.milestones = release.milestones || [];

  return release;
};
