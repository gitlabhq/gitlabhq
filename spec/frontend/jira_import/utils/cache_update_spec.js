import { addInProgressImportToStore } from '~/jira_import/utils/cache_update';
import { IMPORT_STATE } from '~/jira_import/utils/jira_import_utils';
import {
  fullPath,
  queryDetails,
  jiraImportDetailsQueryResponse,
  jiraImportMutationResponse,
} from '../mock_data';

describe('addInProgressImportToStore', () => {
  const store = {
    readQuery: jest.fn(() => jiraImportDetailsQueryResponse),
    writeQuery: jest.fn(),
  };

  describe('when updating the cache', () => {
    beforeEach(() => {
      addInProgressImportToStore(store, jiraImportMutationResponse.jiraImportStart, fullPath);
    });

    it('reads the cache with the correct query', () => {
      expect(store.readQuery).toHaveBeenCalledWith(queryDetails);
    });

    it('writes to the cache with the expected arguments', () => {
      const expected = {
        ...queryDetails,
        data: {
          project: {
            ...jiraImportDetailsQueryResponse.project,
            jiraImportStatus: IMPORT_STATE.SCHEDULED,
            jiraImports: {
              ...jiraImportDetailsQueryResponse.project.jiraImports,
              nodes: jiraImportDetailsQueryResponse.project.jiraImports.nodes.concat(
                jiraImportMutationResponse.jiraImportStart.jiraImport,
              ),
            },
          },
        },
      };

      expect(store.writeQuery).toHaveBeenCalledWith(expected);
    });
  });

  describe('when there are errors', () => {
    beforeEach(() => {
      const jiraImportStart = {
        ...jiraImportMutationResponse.jiraImportStart,
        errors: ['There was an error'],
      };

      addInProgressImportToStore(store, jiraImportStart, fullPath);
    });

    it('does not read from the store', () => {
      expect(store.readQuery).not.toHaveBeenCalled();
    });

    it('does not write to the store', () => {
      expect(store.writeQuery).not.toHaveBeenCalled();
    });
  });
});
