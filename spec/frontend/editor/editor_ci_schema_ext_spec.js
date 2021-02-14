import { languages } from 'monaco-editor';
import { TEST_HOST } from 'helpers/test_constants';
import { EXTENSION_CI_SCHEMA_FILE_NAME_MATCH } from '~/editor/constants';
import EditorLite from '~/editor/editor_lite';
import { CiSchemaExtension } from '~/editor/extensions/editor_ci_schema_ext';

describe('~/editor/editor_ci_config_ext', () => {
  const defaultBlobPath = '.gitlab-ci.yml';

  let editor;
  let instance;
  let editorEl;
  let originalGitlabUrl;

  const createMockEditor = ({ blobPath = defaultBlobPath } = {}) => {
    setFixtures('<div id="editor"></div>');
    editorEl = document.getElementById('editor');
    editor = new EditorLite();
    instance = editor.createInstance({
      el: editorEl,
      blobPath,
      blobContent: '',
    });
    instance.use(new CiSchemaExtension());
  };

  beforeAll(() => {
    originalGitlabUrl = gon.gitlab_url;
    gon.gitlab_url = TEST_HOST;
  });

  afterAll(() => {
    gon.gitlab_url = originalGitlabUrl;
  });

  beforeEach(() => {
    createMockEditor();
  });

  afterEach(() => {
    instance.dispose();
    editorEl.remove();
  });

  describe('registerCiSchema', () => {
    beforeEach(() => {
      jest.spyOn(languages.yaml.yamlDefaults, 'setDiagnosticsOptions');
    });

    describe('register validations options with monaco for yaml language', () => {
      const mockProjectNamespace = 'namespace1';
      const mockProjectPath = 'project1';

      const getConfiguredYmlSchema = () => {
        return languages.yaml.yamlDefaults.setDiagnosticsOptions.mock.calls[0][0].schemas[0];
      };

      it('with expected basic validation configuration', () => {
        instance.registerCiSchema({
          projectNamespace: mockProjectNamespace,
          projectPath: mockProjectPath,
        });

        const expectedOptions = {
          validate: true,
          enableSchemaRequest: true,
          hover: true,
          completion: true,
        };

        expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledTimes(1);
        expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
          expect.objectContaining(expectedOptions),
        );
      });

      it('with an schema uri that contains project and ref', () => {
        const mockRef = 'AABBCCDD';

        instance.registerCiSchema({
          projectNamespace: mockProjectNamespace,
          projectPath: mockProjectPath,
          ref: mockRef,
        });

        expect(getConfiguredYmlSchema()).toEqual({
          uri: `${TEST_HOST}/${mockProjectNamespace}/${mockProjectPath}/-/schema/${mockRef}/${EXTENSION_CI_SCHEMA_FILE_NAME_MATCH}`,
          fileMatch: [defaultBlobPath],
        });
      });

      it('with an alternative file name match', () => {
        createMockEditor({ blobPath: 'dir1/dir2/another-ci-filename.yml' });

        instance.registerCiSchema({
          projectNamespace: mockProjectNamespace,
          projectPath: mockProjectPath,
        });

        expect(getConfiguredYmlSchema()).toEqual({
          uri: `${TEST_HOST}/${mockProjectNamespace}/${mockProjectPath}/-/schema/master/${EXTENSION_CI_SCHEMA_FILE_NAME_MATCH}`,
          fileMatch: ['another-ci-filename.yml'],
        });
      });
    });
  });
});
