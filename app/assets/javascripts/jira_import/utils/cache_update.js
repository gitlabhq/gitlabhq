import produce from 'immer';
import getJiraImportDetailsQuery from '../queries/get_jira_import_details.query.graphql';
import { IMPORT_STATE } from './jira_import_utils';

export const addInProgressImportToStore = (store, jiraImportStart, fullPath) => {
  if (jiraImportStart.errors.length) {
    return;
  }

  const queryDetails = {
    query: getJiraImportDetailsQuery,
    variables: {
      fullPath,
    },
  };

  const sourceData = store.readQuery({
    ...queryDetails,
  });

  store.writeQuery({
    ...queryDetails,
    data: produce(sourceData, draftData => {
      draftData.project.jiraImportStatus = IMPORT_STATE.SCHEDULED; // eslint-disable-line no-param-reassign
      // eslint-disable-next-line no-param-reassign
      draftData.project.jiraImports.nodes = [
        ...sourceData.project.jiraImports.nodes,
        jiraImportStart.jiraImport,
      ];
    }),
  });
};

export default {
  addInProgressImportToStore,
};
