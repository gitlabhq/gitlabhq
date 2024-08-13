import produce from 'immer';
import { createAlert } from '~/alert';

import { DELETE_INTEGRATION_ERROR, ADD_INTEGRATION_ERROR } from './error_messages';

// eslint-disable-next-line max-params
const deleteIntegrationFromStore = (store, query, { httpIntegrationDestroy }, variables) => {
  const integration = httpIntegrationDestroy?.integration;
  if (!integration) {
    return;
  }

  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    draftData.project.alertManagementIntegrations.nodes =
      draftData.project.alertManagementIntegrations.nodes.filter(({ id }) => id !== integration.id);
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const addIntegrationToStore = (
  store,
  query,
  { httpIntegrationCreate, prometheusIntegrationCreate },
  variables,
  // eslint-disable-next-line max-params
) => {
  const integration =
    httpIntegrationCreate?.integration || prometheusIntegrationCreate?.integration;
  if (!integration) {
    return;
  }

  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    draftData.project.alertManagementIntegrations.nodes = [
      integration,
      ...draftData.project.alertManagementIntegrations.nodes,
    ];
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const onError = (data, message) => {
  createAlert({ message });
  throw new Error(data.errors);
};

export const hasErrors = ({ errors = [] }) => errors?.length;

// eslint-disable-next-line max-params
export const updateStoreAfterIntegrationDelete = (store, query, data, variables) => {
  if (hasErrors(data)) {
    onError(data, DELETE_INTEGRATION_ERROR);
  } else {
    deleteIntegrationFromStore(store, query, data, variables);
  }
};

// eslint-disable-next-line max-params
export const updateStoreAfterIntegrationAdd = (store, query, data, variables) => {
  if (hasErrors(data)) {
    onError(data, ADD_INTEGRATION_ERROR);
  } else {
    addIntegrationToStore(store, query, data, variables);
  }
};
