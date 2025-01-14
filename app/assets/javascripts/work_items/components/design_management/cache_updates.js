import produce from 'immer';
import { differenceBy } from 'lodash';
import { createAlert } from '~/alert';
import { findDesignWidget } from '~/work_items/utils';
import { designWidgetOf, extractCurrentDiscussion } from './utils';
import {
  designArchiveError,
  ADD_IMAGE_DIFF_NOTE_ERROR,
  TYPENAME_DISCUSSION,
  TYPENAME_USER,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
} from './constants';

export const hasErrors = ({ errors = [] }) => errors?.length;

const onError = (data, message) => {
  createAlert({ message });
  throw new Error(data.errors);
};

const addNewDesignToStore = (store, designManagementUpload, query) => {
  const sourceData = store.readQuery(query);

  if (!sourceData) {
    return;
  }

  store.writeQuery({
    ...query,
    data: produce(sourceData, (draftData) => {
      const designWidget = findDesignWidget(draftData.workItem.widgets);
      const currentDesigns = designWidget.designCollection.designs.nodes;
      const difference = differenceBy(designManagementUpload.designs, currentDesigns, 'filename');

      const newDesigns = currentDesigns
        .map((design) => {
          return (
            designManagementUpload.designs.find((d) => d.filename === design.filename) || design
          );
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
        ...designWidget.designCollection.versions.nodes,
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
      designWidget.designCollection = updatedDesigns;
    }),
  });
};

const addNewVersionToStore = (store, query, version) => {
  if (!version) return;
  const sourceData = store.readQuery(query);

  const data = produce(sourceData, (draftData) => {
    const designWidget = findDesignWidget(draftData.workItem.widgets);
    designWidget.designCollection.versions.nodes = [
      version,
      ...designWidgetOf(draftData).designCollection.versions.nodes,
    ];
  });

  store.writeQuery({
    ...query,
    data,
  });
};

export const updateStoreAfterUploadDesign = (store, data, query) => {
  if (hasErrors(data)) {
    onError(data, data.errors[0]);
  } else {
    addNewDesignToStore(store, data, query);
  }
};

const moveDesignInStore = (store, designManagementMove, query) => {
  const sourceData = store.readQuery(query);

  const data = produce(sourceData, (draftData) => {
    const designWidget = findDesignWidget(draftData.workItem.widgets);
    designWidget.designCollection.designs.nodes =
      designManagementMove.designCollection.designs.nodes;
  });

  store.writeQuery({
    ...query,
    data,
  });
};

const deleteDesignsFromStore = (store, query, selectedDesigns) => {
  const sourceData = store.readQuery(query);

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftData) => {
    const changedDesigns = designWidgetOf(sourceData).designCollection.designs.nodes.filter(
      (design) => !selectedDesigns.includes(design.filename),
    );
    designWidgetOf(draftData).designCollection.designs.nodes = [...changedDesigns];
  });

  store.writeQuery({
    ...query,
    data,
  });
};

// eslint-disable-next-line max-params
const addImageDiffNoteToStore = (store, createImageDiffNote, query, variables) => {
  const sourceData = store.readQuery({
    query,
    variables,
  });

  if (!sourceData) {
    return;
  }

  const newDiscussion = {
    __typename: TYPENAME_DISCUSSION,
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
    const currentDesign = draftData.designManagement.designAtVersion.design;
    currentDesign.notesCount += 1;
    currentDesign.discussions.nodes = [...currentDesign.discussions.nodes, newDiscussion];

    if (
      !currentDesign.issue.participants.nodes.some(
        (participant) => participant.username === createImageDiffNote.note.author.username,
      )
    ) {
      currentDesign.issue.participants.nodes = [
        ...currentDesign.issue.participants.nodes,
        {
          __typename: TYPENAME_USER,
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

// eslint-disable-next-line max-params
export const updateStoreAfterDesignsArchive = (store, data, query, designs) => {
  if (hasErrors(data)) {
    onError(data, designArchiveError(designs.length));
  } else {
    deleteDesignsFromStore(store, query, designs);
    addNewVersionToStore(store, query, data.version);
  }
};

export const updateWorkItemDesignCurrentTodosWidget = ({ store, todos, query }) => {
  const sourceData = store.readQuery(query);

  if (!sourceData) {
    return;
  }

  const newData = produce(sourceData, (draftState) => {
    draftState.designManagement.designAtVersion.design.currentUserTodos.nodes = todos;
  });

  store.writeQuery({ ...query, data: newData });
};

// eslint-disable-next-line max-params
const updateImageDiffNoteInStore = (store, repositionImageDiffNote, query, variables) => {
  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    const currentDesign = draftData.designManagement.designAtVersion.design;
    const discussion = extractCurrentDiscussion(
      currentDesign.discussions,
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

// eslint-disable-next-line max-params
export const updateStoreAfterAddImageDiffNote = (store, data, query, variables) => {
  if (hasErrors(data)) {
    onError(data, ADD_IMAGE_DIFF_NOTE_ERROR);
  } else {
    addImageDiffNoteToStore(store, data, query, variables);
  }
};

// eslint-disable-next-line max-params
export const updateStoreAfterRepositionImageDiffNote = (store, data, query, queryVariables) => {
  if (hasErrors(data)) {
    onError(data, UPDATE_IMAGE_DIFF_NOTE_ERROR);
  } else {
    updateImageDiffNoteInStore(store, data, query, queryVariables);
  }
};

export const updateDesignsOnStoreAfterReorder = (store, data, query) => {
  if (hasErrors(data)) {
    createAlert({ message: data.errors[0] });
  } else {
    moveDesignInStore(store, data, query);
  }
};
