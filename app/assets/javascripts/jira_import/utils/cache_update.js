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

  const cacheData = store.readQuery({
    ...queryDetails,
  });

  store.writeQuery({
    ...queryDetails,
    data: {
      project: {
        ...cacheData.project,
        jiraImportStatus: IMPORT_STATE.SCHEDULED,
        jiraImports: {
          ...cacheData.project.jiraImports,
          nodes: cacheData.project.jiraImports.nodes.concat(jiraImportStart.jiraImport),
        },
      },
    },
  });
};

export default {
  addInProgressImportToStore,
};
