import { shallowMount } from '@vue/test-utils';

import { EDITOR_READY_EVENT } from '~/editor/constants';
import { SOURCE_EDITOR_DEBOUNCE } from '~/ci/pipeline_editor/constants';
import TextEditor from '~/ci/pipeline_editor/components/editor/text_editor.vue';
import {
  mockCiConfigPath,
  mockCiYml,
  mockCommitSha,
  mockProjectPath,
  mockProjectNamespace,
  mockDefaultBranch,
} from '../../mock_data';

describe('Pipeline Editor | Text editor component', () => {
  let wrapper;

  let editorReadyListener;
  let mockUse;
  let mockRegisterCiSchema;
  let mockEditorInstance;
  let editorInstanceDetail;

  const MockSourceEditor = {
    template: '<div/>',
    props: ['value', 'fileName', 'editorOptions', 'debounceValue'],
  };

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
        SourceEditor: MockSourceEditor,
      },
    });
  };

  const findEditor = () => wrapper.findComponent(MockSourceEditor);

  beforeEach(() => {
    editorReadyListener = jest.fn();
    mockUse = jest.fn();
    mockRegisterCiSchema = jest.fn();
    mockEditorInstance = {
      use: mockUse,
      registerCiSchema: mockRegisterCiSchema,
    };
    editorInstanceDetail = {
      detail: {
        instance: mockEditorInstance,
      },
    };
  });

  afterEach(() => {
    wrapper.destroy();

    mockUse.mockClear();
    mockRegisterCiSchema.mockClear();
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
      findEditor().vm.$emit(EDITOR_READY_EVENT, editorInstanceDetail);

      expect(editorReadyListener).toHaveBeenCalled();
    });
  });

  describe('CI schema', () => {
    beforeEach(() => {
      createComponent();
      findEditor().vm.$emit(EDITOR_READY_EVENT, editorInstanceDetail);
    });

    it('configures editor with syntax highlight', () => {
      expect(mockUse).toHaveBeenCalledTimes(1);
      expect(mockRegisterCiSchema).toHaveBeenCalledTimes(1);
    });
  });
});
