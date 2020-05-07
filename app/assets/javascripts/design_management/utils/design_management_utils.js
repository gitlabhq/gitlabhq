import { uniqueId } from 'lodash';
import { VALID_DESIGN_FILE_MIMETYPE } from '../constants';

export const isValidDesignFile = ({ type }) =>
  (type.match(VALID_DESIGN_FILE_MIMETYPE.regex) || []).length > 0;

/**
 * Returns formatted array that doesn't contain
 * `edges`->`node` nesting
 *
 * @param {Array} elements
 */

export const extractNodes = elements => elements.edges.map(({ node }) => node);

/**
 * Returns formatted array of discussions that doesn't contain
 * `edges`->`node` nesting for child notes
 *
 * @param {Array} discussions
 */

export const extractDiscussions = discussions =>
  discussions.nodes.map(discussion => ({
    ...discussion,
    notes: discussion.notes.nodes,
  }));

/**
 * Returns a discussion with the given id from discussions array
 *
 * @param {Array} discussions
 */

export const extractCurrentDiscussion = (discussions, id) =>
  discussions.nodes.find(discussion => discussion.id === id);

export const findVersionId = id => (id.match('::Version/(.+$)') || [])[1];

export const findNoteId = id => (id.match('DiffNote/(.+$)') || [])[1];

export const extractDesigns = data => data.project.issue.designCollection.designs.edges;

export const extractDesign = data => (extractDesigns(data) || [])[0]?.node;

/**
 * Generates optimistic response for a design upload mutation
 * @param {Array<File>} files
 */
export const designUploadOptimisticResponse = files => {
  const designs = files.map(file => ({
    // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
    // eslint-disable-next-line @gitlab/require-i18n-strings
    __typename: 'Design',
    id: -uniqueId(),
    image: '',
    imageV432x230: '',
    filename: file.name,
    fullPath: '',
    notesCount: 0,
    event: 'NONE',
    diffRefs: {
      __typename: 'DiffRefs',
      baseSha: '',
      startSha: '',
      headSha: '',
    },
    discussions: {
      __typename: 'DesignDiscussion',
      nodes: [],
    },
    versions: {
      __typename: 'DesignVersionConnection',
      edges: {
        __typename: 'DesignVersionEdge',
        node: {
          __typename: 'DesignVersion',
          id: -uniqueId(),
          sha: -uniqueId(),
        },
      },
    },
  }));

  return {
    // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
    // eslint-disable-next-line @gitlab/require-i18n-strings
    __typename: 'Mutation',
    designManagementUpload: {
      __typename: 'DesignManagementUploadPayload',
      designs,
      skippedDesigns: [],
      errors: [],
    },
  };
};

/**
 * Generates optimistic response for a design upload mutation
 * @param {Array<File>} files
 */
export const updateImageDiffNoteOptimisticResponse = (note, { position }) => ({
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
  // eslint-disable-next-line @gitlab/require-i18n-strings
  __typename: 'Mutation',
  updateImageDiffNote: {
    __typename: 'UpdateImageDiffNotePayload',
    note: {
      ...note,
      position: {
        ...note.position,
        ...position,
      },
    },
    errors: [],
  },
});

const normalizeAuthor = author => ({
  ...author,
  web_url: author.webUrl,
  avatar_url: author.avatarUrl,
});

export const extractParticipants = users => users.edges.map(({ node }) => normalizeAuthor(node));
