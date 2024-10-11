import produce from 'immer';
import { differenceBy } from 'lodash';
import { createAlert } from '~/alert';
import { findDesignWidget } from '~/work_items/utils';
import { designWidgetOf } from './utils';
import { designArchiveError } from './constants';

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
    draftState.localDesign.currentUserTodos.nodes = todos;
  });

  store.writeQuery({ ...query, data: newData });
};
