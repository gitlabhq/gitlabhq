/* eslint-disable @gitlab/require-i18n-strings */

import produce from 'immer';
import { differenceBy } from 'lodash';
import createFlash from '~/flash';
import { extractCurrentDiscussion, extractDesign, extractDesigns } from './design_management_utils';
import {
  ADD_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  DELETE_DESIGN_TODO_ERROR,
  designDeletionError,
} from './error_messages';

const designsOf = (data) => data.project.issue.designCollection.designs;

const deleteDesignsFromStore = (store, query, selectedDesigns) => {
  const sourceData = store.readQuery(query);

  const data = produce(sourceData, (draftData) => {
    const changedDesigns = designsOf(sourceData).nodes.filter(
      (design) => !selectedDesigns.includes(design.filename),
    );
    designsOf(draftData).nodes = [...changedDesigns];
  });

  store.writeQuery({
    ...query,
    data,
  });
};

/**
 * Adds a new version of designs to store
 *
 * @param {Object} store
 * @param {Object} query
 * @param {Object} version
 */
const addNewVersionToStore = (store, query, version) => {
  if (!version) return;
  const sourceData = store.readQuery(query);

  const data = produce(sourceData, (draftData) => {
    draftData.project.issue.designCollection.versions.nodes = [
      version,
      ...draftData.project.issue.designCollection.versions.nodes,
    ];
  });

  store.writeQuery({
    ...query,
    data,
  });
};

const addImageDiffNoteToStore = (store, createImageDiffNote, query, variables) => {
  const sourceData = store.readQuery({
    query,
    variables,
  });

  const newDiscussion = {
    __typename: 'Discussion',
    id: createImageDiffNote.note.discussion.id,
    replyId: createImageDiffNote.note.discussion.replyId,
    resolvable: true,
    resolved: false,
    resolvedAt: null,
    resolvedBy: null,
    notes: {
      __typename: 'NoteConnection',
      nodes: [createImageDiffNote.note],
    },
  };

  const data = produce(sourceData, (draftData) => {
    const design = extractDesign(draftData);
    design.notesCount += 1;
    design.discussions.nodes = [...design.discussions.nodes, newDiscussion];

    if (
      !design.issue.participants.nodes.some(
        (participant) => participant.username === createImageDiffNote.note.author.username,
      )
    ) {
      design.issue.participants.nodes = [
        ...design.issue.participants.nodes,
        {
          __typename: 'User',
          ...createImageDiffNote.note.author,
        },
      ];
    }
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const updateImageDiffNoteInStore = (store, repositionImageDiffNote, query, variables) => {
  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    const design = extractDesign(draftData);
    const discussion = extractCurrentDiscussion(
      design.discussions,
      repositionImageDiffNote.note.discussion.id,
    );

    discussion.notes = {
      ...discussion.notes,
      nodes: [repositionImageDiffNote.note, ...discussion.notes.nodes.slice(1)],
    };
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const addNewDesignToStore = (store, designManagementUpload, query) => {
  const sourceData = store.readQuery(query);

  const data = produce(sourceData, (draftData) => {
    const currentDesigns = extractDesigns(draftData);
    const difference = differenceBy(designManagementUpload.designs, currentDesigns, 'filename');

    const newDesigns = currentDesigns
      .map((design) => {
        return designManagementUpload.designs.find((d) => d.filename === design.filename) || design;
      })
      .concat(difference);

    let newVersionNode;
    const findNewVersions = designManagementUpload.designs.find((design) => design.versions);

    if (findNewVersions) {
      const findNewVersionsNodes = findNewVersions.versions.nodes;

      if (findNewVersionsNodes && findNewVersionsNodes.length) {
        newVersionNode = [findNewVersionsNodes[0]];
      }
    }

    const newVersions = [
      ...(newVersionNode || []),
      ...draftData.project.issue.designCollection.versions.nodes,
    ];

    const updatedDesigns = {
      __typename: 'DesignCollection',
      copyState: 'READY',
      designs: {
        __typename: 'DesignConnection',
        nodes: newDesigns,
      },
      versions: {
        __typename: 'DesignVersionConnection',
        nodes: newVersions,
      },
    };
    draftData.project.issue.designCollection = updatedDesigns;
  });

  store.writeQuery({
    ...query,
    data,
  });
};

const moveDesignInStore = (store, designManagementMove, query) => {
  const sourceData = store.readQuery(query);

  const data = produce(sourceData, (draftData) => {
    draftData.project.issue.designCollection.designs =
      designManagementMove.designCollection.designs;
  });

  store.writeQuery({
    ...query,
    data,
  });
};

export const addPendingTodoToStore = (store, pendingTodo, query, queryVariables) => {
  const sourceData = store.readQuery({
    query,
    variables: queryVariables,
  });

  const data = produce(sourceData, (draftData) => {
    const design = extractDesign(draftData);
    const existingTodos = design.currentUserTodos?.nodes || [];
    const newTodoNodes = [...existingTodos, { ...pendingTodo, __typename: 'Todo' }];

    if (!design.currentUserTodos) {
      design.currentUserTodos = {
        __typename: 'TodoConnection',
        nodes: newTodoNodes,
      };
    } else {
      design.currentUserTodos.nodes = newTodoNodes;
    }
  });

  store.writeQuery({ query, variables: queryVariables, data });
};

export const deletePendingTodoFromStore = (store, todoMarkDone, query, queryVariables) => {
  const sourceData = store.readQuery({
    query,
    variables: queryVariables,
  });

  const {
    todo: { id: todoId },
  } = todoMarkDone;
  const data = produce(sourceData, (draftData) => {
    const design = extractDesign(draftData);
    const existingTodos = design.currentUserTodos?.nodes || [];

    design.currentUserTodos.nodes = existingTodos.filter(({ id }) => id !== todoId);
  });

  store.writeQuery({ query, variables: queryVariables, data });
};

const onError = (data, message) => {
  createFlash({ message });
  throw new Error(data.errors);
};

export const hasErrors = ({ errors = [] }) => errors?.length;

/**
 * Updates a store after design deletion
 *
 * @param {Object} store
 * @param {Object} data
 * @param {Object} query
 * @param {Array} designs
 */
export const updateStoreAfterDesignsDelete = (store, data, query, designs) => {
  if (hasErrors(data)) {
    onError(data, designDeletionError({ singular: designs.length === 1 }));
  } else {
    deleteDesignsFromStore(store, query, designs);
    addNewVersionToStore(store, query, data.version);
  }
};

export const updateStoreAfterAddImageDiffNote = (store, data, query, queryVariables) => {
  if (hasErrors(data)) {
    onError(data, ADD_IMAGE_DIFF_NOTE_ERROR);
  } else {
    addImageDiffNoteToStore(store, data, query, queryVariables);
  }
};

export const updateStoreAfterRepositionImageDiffNote = (store, data, query, queryVariables) => {
  if (hasErrors(data)) {
    onError(data, UPDATE_IMAGE_DIFF_NOTE_ERROR);
  } else {
    updateImageDiffNoteInStore(store, data, query, queryVariables);
  }
};

export const updateStoreAfterUploadDesign = (store, data, query) => {
  if (hasErrors(data)) {
    onError(data, data.errors[0]);
  } else {
    addNewDesignToStore(store, data, query);
  }
};

export const updateDesignsOnStoreAfterReorder = (store, data, query) => {
  if (hasErrors(data)) {
    createFlash({ message: data.errors[0] });
  } else {
    moveDesignInStore(store, data, query);
  }
};

export const updateStoreAfterDeleteDesignTodo = (store, data, query, queryVariables) => {
  if (hasErrors(data)) {
    onError(data, DELETE_DESIGN_TODO_ERROR);
  } else {
    deletePendingTodoFromStore(store, data, query, queryVariables);
  }
};
