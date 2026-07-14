import { gql } from '@apollo/client/core';

export const LABEL_PREFIX = 'label_';

/**
 * A GraphQL query building function which accepts multiple
 * label names to use as search queries for a project or group.
 *
 * @param {Array<String>} The queries for the label search
 * @param {Boolean} Search within a Group (false), or a Project (true)
 *
 * @return {String} the generated GraphQL query string
 */
export default (labelNames, isProject) => {
  const labels = labelNames.map((label, index) => {
    let args = `title: "${label}", includeAncestorGroups: true`;
    if (!isProject) {
      args += ', includeDescendantGroups: true';
    }

    // eslint-disable-next-line @gitlab/require-i18n-strings
    return `
      ${LABEL_PREFIX}${index}: labels(${args}) {
        nodes {
          id
          title
          color
        }
      }
    `;
  });

  return gql`
    query($fullPath: ID!) {
      namespace: ${isProject ? 'project' : 'group'}(fullPath: $fullPath) {
        id
        ${labels}
      }
    }
  `;
};
