import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import getIdeProject from 'ee_else_ce/ide/queries/get_ide_project.query.graphql';
import Api from '~/api';
import dismissUserCallout from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import services from '~/ide/services';
import { query, mutate } from '~/ide/services/gql';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import ciConfig from '~/pipeline_editor/graphql/queries/ci_config.graphql';
import { projectData } from '../mock_data';

jest.mock('~/api');
jest.mock('~/ide/services/gql');

const TEST_NAMESPACE = 'alice';
const TEST_PROJECT = 'wonderland';
const TEST_PROJECT_ID = `${TEST_NAMESPACE}/${TEST_PROJECT}`;
const TEST_BRANCH = 'main-patch-123';
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

  describe('getRawFileData', () => {
    it("resolves with a file's content if its a tempfile and it isn't renamed", () => {
      const file = {
        path: 'file',
        tempFile: true,
        content: 'content',
        raw: 'raw content',
      };

      return services.getRawFileData(file).then((raw) => {
        expect(raw).toBe('content');
      });
    });

    it('resolves with file.raw if the file is renamed', () => {
      const file = {
        path: 'file',
        tempFile: true,
        content: 'content',
        prevPath: 'old_path',
        raw: 'raw content',
      };

      return services.getRawFileData(file).then((raw) => {
        expect(raw).toBe('raw content');
      });
    });

    it('returns file.raw if it exists', () => {
      const file = {
        path: 'file',
        content: 'content',
        raw: 'raw content',
      };

      return services.getRawFileData(file).then((raw) => {
        expect(raw).toBe('raw content');
      });
    });

    it("returns file.raw if file.raw is empty but file.rawPath doesn't exist", () => {
      const file = {
        path: 'file',
        content: 'content',
        raw: '',
      };

      return services.getRawFileData(file).then((raw) => {
        expect(raw).toBe('');
      });
    });

    describe("if file.rawPath exists but file.raw doesn't exist", () => {
      let file;
      let mock;
      beforeEach(() => {
        file = {
          path: 'file',
          content: 'content',
          raw: '',
          rawPath: 'some_raw_path',
        };

        mock = new MockAdapter(axios);
        mock.onGet(file.rawPath).reply(200, 'raw content');

        jest.spyOn(axios, 'get');
      });

      afterEach(() => {
        mock.restore();
      });

      it('sends a request to file.rawPath', () => {
        return services.getRawFileData(file).then((raw) => {
          expect(axios.get).toHaveBeenCalledWith(file.rawPath, {
            transformResponse: [expect.any(Function)],
          });
          expect(raw).toEqual('raw content');
        });
      });

      it('returns arraybuffer for binary files', () => {
        file.binary = true;

        return services.getRawFileData(file).then((raw) => {
          expect(axios.get).toHaveBeenCalledWith(file.rawPath, {
            transformResponse: [expect.any(Function)],
            responseType: 'arraybuffer',
          });
          expect(raw).toEqual('raw content');
        });
      });
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

      return services.getBaseRawFileData(file, TEST_PROJECT_ID, TEST_COMMIT_SHA).then((content) => {
        expect(content).toEqual(TEST_FILE_CONTENTS);
      });
    });

    it('gives back file.baseRaw for files for temp files', () => {
      file.tempFile = true;
      file.baseRaw = TEST_FILE_CONTENTS;

      return services.getBaseRawFileData(file, TEST_PROJECT_ID, TEST_COMMIT_SHA).then((content) => {
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
          services.getBaseRawFileData(file, TEST_PROJECT_ID, TEST_COMMIT_SHA).then((content) => {
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
      query.mockReturnValue(Promise.resolve({ data: { project: gqlProjectData } }));

      return services.getProjectData(TEST_NAMESPACE, TEST_PROJECT).then((response) => {
        expect(response).toEqual({ data: { ...projectData, ...gqlProjectData } });
        expect(Api.project).toHaveBeenCalledWith(TEST_PROJECT_ID);
        expect(query).toHaveBeenCalledWith({
          query: getIdeProject,
          variables: {
            projectPath: TEST_PROJECT_ID,
          },
        });
      });
    });
  });

  describe('getFiles', () => {
    let mock;
    let relativeUrlRoot;
    const TEST_RELATIVE_URL_ROOT = 'blah-blah';

    beforeEach(() => {
      jest.spyOn(axios, 'get');
      relativeUrlRoot = gon.relative_url_root;
      gon.relative_url_root = TEST_RELATIVE_URL_ROOT;

      mock = new MockAdapter(axios);

      mock
        .onGet(`${TEST_RELATIVE_URL_ROOT}/${TEST_PROJECT_ID}/-/files/${TEST_COMMIT_SHA}`)
        .reply(200, [TEST_FILE_PATH]);
    });

    afterEach(() => {
      mock.restore();
      gon.relative_url_root = relativeUrlRoot;
    });

    it('initates the api call based on the passed path and commit hash', () => {
      return services.getFiles(TEST_PROJECT_ID, TEST_COMMIT_SHA).then(({ data }) => {
        expect(axios.get).toHaveBeenCalledWith(
          `${gon.relative_url_root}/${TEST_PROJECT_ID}/-/files/${TEST_COMMIT_SHA}`,
          expect.any(Object),
        );
        expect(data).toEqual([TEST_FILE_PATH]);
      });
    });
  });

  describe('pingUsage', () => {
    let mock;
    let relativeUrlRoot;
    const TEST_RELATIVE_URL_ROOT = 'blah-blah';

    beforeEach(() => {
      jest.spyOn(axios, 'post');
      relativeUrlRoot = gon.relative_url_root;
      gon.relative_url_root = TEST_RELATIVE_URL_ROOT;

      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      gon.relative_url_root = relativeUrlRoot;
    });

    it('posts to usage endpoint', () => {
      const TEST_PROJECT_PATH = 'foo/bar';
      const axiosURL = `${TEST_RELATIVE_URL_ROOT}/${TEST_PROJECT_PATH}/service_ping/web_ide_pipelines_count`;

      mock.onPost(axiosURL).reply(200);

      return services.pingUsage(TEST_PROJECT_PATH).then(() => {
        expect(axios.post).toHaveBeenCalledWith(axiosURL);
      });
    });
  });
  describe('getCiConfig', () => {
    const TEST_PROJECT_PATH = 'foo/bar';
    const TEST_CI_CONFIG = 'test config';

    it('queries with the given CI config and project', () => {
      const result = { data: { ciConfig: { test: 'data' } } };
      query.mockResolvedValue(result);
      return services.getCiConfig(TEST_PROJECT_PATH, TEST_CI_CONFIG).then((data) => {
        expect(data).toEqual(result.data.ciConfig);
        expect(query).toHaveBeenCalledWith({
          query: ciConfig,
          variables: { projectPath: TEST_PROJECT_PATH, content: TEST_CI_CONFIG },
        });
      });
    });
  });
  describe('dismissUserCallout', () => {
    it('mutates the callout to dismiss', () => {
      const result = { data: { callouts: { test: 'data' } } };
      mutate.mockResolvedValue(result);
      return services.dismissUserCallout('test').then((data) => {
        expect(data).toEqual(result.data);
        expect(mutate).toHaveBeenCalledWith({
          mutation: dismissUserCallout,
          variables: { input: { featureName: 'test' } },
        });
      });
    });
  });
});
