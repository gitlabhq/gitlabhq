import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import services from '~/ide/services';
import Api from '~/api';
import gqClient from '~/ide/services/gql';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import getUserPermissions from '~/ide/queries/getUserPermissions.query.graphql';
import { projectData } from '../mock_data';

jest.mock('~/api');
jest.mock('~/ide/services/gql');

const TEST_NAMESPACE = 'alice';
const TEST_PROJECT = 'wonderland';
const TEST_PROJECT_ID = `${TEST_NAMESPACE}/${TEST_PROJECT}`;
const TEST_BRANCH = 'master-patch-123';
const TEST_COMMIT_SHA = '123456789';
const TEST_FILE_PATH = 'README2.md';
const TEST_FILE_OLD_PATH = 'OLD_README2.md';
const TEST_FILE_PATH_SPECIAL = 'READM?ME/abc';
const TEST_FILE_CONTENTS = 'raw file content';

describe('IDE services', () => {
  describe('commit', () => {
    let payload;

    beforeEach(() => {
      payload = {
        branch: TEST_BRANCH,
        commit_message: 'Hello world',
        actions: [],
        start_sha: TEST_COMMIT_SHA,
      };

      Api.commitMultiple.mockReturnValue(Promise.resolve());
    });

    it('should commit', () => {
      services.commit(TEST_PROJECT_ID, payload);

      expect(Api.commitMultiple).toHaveBeenCalledWith(TEST_PROJECT_ID, payload);
    });
  });

  describe('getBaseRawFileData', () => {
    let file;
    let mock;

    beforeEach(() => {
      file = {
        mrChange: null,
        projectId: TEST_PROJECT_ID,
        path: TEST_FILE_PATH,
      };

      jest.spyOn(axios, 'get');

      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('gives back file.baseRaw for files with that property present', () => {
      file.baseRaw = TEST_FILE_CONTENTS;

      return services.getBaseRawFileData(file, TEST_COMMIT_SHA).then(content => {
        expect(content).toEqual(TEST_FILE_CONTENTS);
      });
    });

    it('gives back file.baseRaw for files for temp files', () => {
      file.tempFile = true;
      file.baseRaw = TEST_FILE_CONTENTS;

      return services.getBaseRawFileData(file, TEST_COMMIT_SHA).then(content => {
        expect(content).toEqual(TEST_FILE_CONTENTS);
      });
    });

    describe.each`
      relativeUrlRoot | filePath                  | isRenamed
      ${''}           | ${TEST_FILE_PATH}         | ${false}
      ${''}           | ${TEST_FILE_OLD_PATH}     | ${true}
      ${''}           | ${TEST_FILE_PATH_SPECIAL} | ${false}
      ${''}           | ${TEST_FILE_PATH_SPECIAL} | ${true}
      ${'gitlab'}     | ${TEST_FILE_OLD_PATH}     | ${true}
    `(
      'with relativeUrlRoot ($relativeUrlRoot) and filePath ($filePath) and isRenamed ($isRenamed)',
      ({ relativeUrlRoot, filePath, isRenamed }) => {
        beforeEach(() => {
          if (isRenamed) {
            file.mrChange = {
              renamed_file: true,
              old_path: filePath,
            };
          } else {
            file.path = filePath;
          }

          gon.relative_url_root = relativeUrlRoot;

          mock
            .onGet(
              `${relativeUrlRoot}/${TEST_PROJECT_ID}/-/raw/${TEST_COMMIT_SHA}/${escapeFileUrl(
                filePath,
              )}`,
            )
            .reply(200, TEST_FILE_CONTENTS);
        });

        it('fetches file content', () =>
          services.getBaseRawFileData(file, TEST_COMMIT_SHA).then(content => {
            expect(content).toEqual(TEST_FILE_CONTENTS);
          }));
      },
    );
  });

  describe('getProjectData', () => {
    it('combines gql and API requests', () => {
      const gqlProjectData = {
        userPermissions: {
          bogus: true,
        },
      };
      Api.project.mockReturnValue(Promise.resolve({ data: { ...projectData } }));
      gqClient.query.mockReturnValue(Promise.resolve({ data: { project: gqlProjectData } }));

      return services.getProjectData(TEST_NAMESPACE, TEST_PROJECT).then(response => {
        expect(response).toEqual({ data: { ...projectData, ...gqlProjectData } });
        expect(Api.project).toHaveBeenCalledWith(TEST_PROJECT_ID);
        expect(gqClient.query).toHaveBeenCalledWith({
          query: getUserPermissions,
          variables: {
            projectPath: TEST_PROJECT_ID,
          },
        });
      });
    });
  });
});
