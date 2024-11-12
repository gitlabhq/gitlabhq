import { uniqueId } from 'lodash';
import { VALID_DESIGN_FILE_MIMETYPE } from '../constants';

export const isValidDesignFile = ({ type }) =>
  (type.match(VALID_DESIGN_FILE_MIMETYPE.regex) || []).length > 0;

/**
 * Returns formatted array of discussions
 *
 * @param {Array} discussions
 */

export const extractDiscussions = (discussions) =>
  discussions.nodes.map((discussion, index) => ({
    ...discussion,
    index: index + 1,
    notes: discussion.notes.nodes,
  }));

/**
 * Returns a discussion with the given id from discussions array
 *
 * @param {Array} discussions
 */

export const extractCurrentDiscussion = (discussions, id) =>
  discussions.nodes.find((discussion) => discussion.id === id);

export const findVersionId = (id) => (id.match('::Version/(.+$)') || [])[1];

export const findNoteId = (id) => (id.match('DiffNote/(.+$)') || [])[1];

export const findIssueId = (id) => (id.match('Issue/(.+$)') || [])[1];

export const findDesignId = (id) => (id.match('Design/(.+$)') || [])[1];

export const extractDesigns = (data) => data.project.issue.designCollection.designs.nodes;

export const extractDesign = (data) => (extractDesigns(data) || [])[0];

export const toDiffNoteGid = (noteId) => `gid://gitlab/DiffNote/${noteId}`;

/**
 * Return the note ID from a URL hash parameter
 * @param {String} urlHash URL hash, including `#` prefix
 */
export const extractDesignNoteId = (urlHash) => {
  const [, noteId] = urlHash.match('#note_([0-9]+$)') || [];
  return noteId || null;
};

/**
 * Generates optimistic response for a design upload mutation
 * @param {Array<File>} files
 */
export const designUploadOptimisticResponse = (files) => {
  const designs = files.map((file) => ({
    __typename: 'Design',
    id: -uniqueId(),
    image: '',
    imageV432x230: '',
    description: '',
    descriptionHtml: '',
    filename: file.name,
    fullPath: '',
    notesCount: 0,
    event: 'NONE',
    currentUserTodos: {
      __typename: 'TodoConnection',
      nodes: [],
    },
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
      nodes: {
        __typename: 'DesignVersion',
        id: -uniqueId(),
        sha: -uniqueId(),
        createdAt: '',
        author: {
          __typename: 'UserCore',
          id: -uniqueId(),
          name: '',
          avatarUrl: '',
        },
      },
    },
  }));

  return {
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
 *  @param {Object} note
 *  @param {Object} position
 */
export const repositionImageDiffNoteOptimisticResponse = (note, { position }) => ({
  __typename: 'Mutation',
  repositionImageDiffNote: {
    __typename: 'RepositionImageDiffNotePayload',
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

/**
 * Generates optimistic response for a design upload mutation
 * @param {Array} designs
 */
export const moveDesignOptimisticResponse = (designs) => ({
  __typename: 'Mutation',
  designManagementMove: {
    __typename: 'DesignManagementMovePayload',
    designCollection: {
      __typename: 'DesignCollection',
      designs: {
        __typename: 'DesignConnection',
        nodes: designs,
      },
    },
    errors: [],
  },
});

const normalizeAuthor = (author) => ({
  ...author,
  web_url: author.webUrl,
  avatar_url: author.avatarUrl,
});

export const extractParticipants = (users) => users.map((node) => normalizeAuthor(node));

export const getPageLayoutElement = () => document.querySelector('.layout-page');

/**
 * Extract the ID of the To-Do for a given 'delete' path
 * Example of todoDeletePath: /delete/1234
 * @param {String} todoDeletePath delete_path from REST API response
 */
export const extractTodoIdFromDeletePath = (todoDeletePath) =>
  (todoDeletePath.match('todos/([0-9]+$)') || [])[1];

const createTodoGid = (todoId) => {
  return `gid://gitlab/Todo/${todoId}`;
};

export const createPendingTodo = (todoId) => {
  return {
    __typename: 'Todo',
    id: createTodoGid(todoId),
  };
};
