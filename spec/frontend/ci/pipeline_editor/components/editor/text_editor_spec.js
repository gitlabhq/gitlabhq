import { shallowMount } from '@vue/test-utils';
import { editor as monacoEditor } from 'monaco-editor';

import SourceEditor from '~/vue_shared/components/source_editor.vue';
import { EDITOR_READY_EVENT } from '~/editor/constants';
import { CiSchemaExtension as MockedCiSchemaExtension } from '~/editor/extensions/source_editor_ci_schema_ext';
import { SOURCE_EDITOR_DEBOUNCE } from '~/ci/pipeline_editor/constants';
import eventHub, { SCROLL_EDITOR_TO_BOTTOM } from '~/ci/pipeline_editor/event_hub';
import TextEditor from '~/ci/pipeline_editor/components/editor/text_editor.vue';
import {
  mockCiConfigPath,
  mockCiYml,
  mockCommitSha,
  mockProjectPath,
  mockProjectNamespace,
  mockDefaultBranch,
} from '../../mock_data';

jest.mock('monaco-editor');
jest.mock('~/editor/extensions/source_editor_ci_schema_ext', () => {
  const { createMockSourceEditorExtension } = jest.requireActual(
    'helpers/create_mock_source_editor_extension',
  );
  const { CiSchemaExtension } = jest.requireActual(
    '~/editor/extensions/source_editor_ci_schema_ext',
  );

  return {
    CiSchemaExtension: createMockSourceEditorExtension(CiSchemaExtension),
  };
});

describe('Pipeline Editor | Text editor component', () => {
  let wrapper;

  let editorReadyListener;

  const getMonacoEditor = () => monacoEditor.create.mock.results[0].value;

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(TextEditor, {
      provide: {
        projectPath: mockProjectPath,
        projectNamespace: mockProjectNamespace,
        ciConfigPath: mockCiConfigPath,
        defaultBranch: mockDefaultBranch,
      },
      propsData: {
        commitSha: mockCommitSha,
      },
      attrs: {
        value: mockCiYml,
      },
      listeners: {
        [EDITOR_READY_EVENT]: editorReadyListener,
      },
      stubs: {
        SourceEditor,
      },
    });
  };

  const findEditor = () => wrapper.findComponent(SourceEditor);

  beforeEach(() => {
    jest.spyOn(monacoEditor, 'create');

    editorReadyListener = jest.fn();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('contains an editor', () => {
      expect(findEditor().exists()).toBe(true);
    });

    it('editor contains the value provided', () => {
      expect(findEditor().props('value')).toBe(mockCiYml);
    });

    it('editor is configured for the CI config path', () => {
      expect(findEditor().props('fileName')).toBe(mockCiConfigPath);
    });

    it('passes down editor configs options', () => {
      expect(findEditor().props('editorOptions')).toEqual({ quickSuggestions: true });
    });

    it('passes down editor debounce value', () => {
      expect(findEditor().props('debounceValue')).toBe(SOURCE_EDITOR_DEBOUNCE);
    });

    it('bubbles up events', () => {
      expect(editorReadyListener).toHaveBeenCalled();
    });

    it('scrolls editor to bottom on scroll editor to bottom event', () => {
      const setScrollTop = jest.spyOn(getMonacoEditor(), 'setScrollTop');

      eventHub.$emit(SCROLL_EDITOR_TO_BOTTOM);

      expect(setScrollTop).toHaveBeenCalledWith(getMonacoEditor().getScrollHeight());
    });

    it('when destroyed, destroys scroll listener', () => {
      const setScrollTop = jest.spyOn(getMonacoEditor(), 'setScrollTop');

      wrapper.destroy();
      eventHub.$emit(SCROLL_EDITOR_TO_BOTTOM);

      expect(setScrollTop).not.toHaveBeenCalled();
    });
  });

  describe('CI schema', () => {
    beforeEach(() => {
      createComponent();
    });

    it('configures editor with syntax highlight', () => {
      expect(MockedCiSchemaExtension.mockedMethods.registerCiSchema).toHaveBeenCalledTimes(1);
    });
  });
});
