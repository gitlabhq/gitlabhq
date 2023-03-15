import { setDiagnosticsOptions } from 'monaco-yaml';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import { CiSchemaExtension } from '~/editor/extensions/source_editor_ci_schema_ext';
import ciSchemaPath from '~/editor/schema/ci.json';
import SourceEditor from '~/editor/source_editor';

// Webpack is configured to use file-loader for the CI schema; mimic that here
jest.mock('~/editor/schema/ci.json', () => '/assets/ci.json');

const mockRef = 'AABBCCDD';

describe('~/editor/editor_ci_config_ext', () => {
  const defaultBlobPath = '.gitlab-ci.yml';
  const expectedSchemaUri = `${TEST_HOST}${ciSchemaPath}`;

  let editor;
  let instance;
  let editorEl;

  const createMockEditor = ({ blobPath = defaultBlobPath } = {}) => {
    setHTMLFixture('<div id="editor"></div>');
    editorEl = document.getElementById('editor');
    editor = new SourceEditor();
    instance = editor.createInstance({
      el: editorEl,
      blobPath,
      blobContent: '',
    });
    instance.use({ definition: CiSchemaExtension });
  };

  beforeEach(() => {
    gon.gitlab_url = TEST_HOST;
    createMockEditor();
  });

  afterEach(() => {
    instance.dispose();

    editorEl.remove();
    resetHTMLFixture();
  });

  describe('registerCiSchema', () => {
    describe('register validations options with monaco for yaml language', () => {
      const mockProjectNamespace = 'namespace1';
      const mockProjectPath = 'project1';

      const getConfiguredYmlSchema = () => {
        return setDiagnosticsOptions.mock.calls[0][0].schemas[0];
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

        expect(setDiagnosticsOptions).toHaveBeenCalledTimes(1);
        expect(setDiagnosticsOptions).toHaveBeenCalledWith(
          expect.objectContaining(expectedOptions),
        );
      });

      it('with an schema uri that contains project and ref', () => {
        instance.registerCiSchema({
          projectNamespace: mockProjectNamespace,
          projectPath: mockProjectPath,
          ref: mockRef,
        });

        expect(getConfiguredYmlSchema()).toEqual({
          uri: expectedSchemaUri,
          fileMatch: [defaultBlobPath],
        });
      });

      it('with an alternative file name match', () => {
        createMockEditor({ blobPath: 'dir1/dir2/another-ci-filename.yml' });
        instance.registerCiSchema({
          projectNamespace: mockProjectNamespace,
          projectPath: mockProjectPath,
          ref: mockRef,
        });

        expect(getConfiguredYmlSchema()).toEqual({
          uri: expectedSchemaUri,
          fileMatch: ['another-ci-filename.yml'],
        });
      });
    });
  });
});
