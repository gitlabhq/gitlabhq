import { shallowMount } from '@vue/test-utils';

import { EDITOR_READY_EVENT } from '~/editor/constants';
import { EditorLiteExtension } from '~/editor/extensions/editor_lite_extension_base';
import TextEditor from '~/pipeline_editor/components/editor/text_editor.vue';
import {
  mockCiConfigPath,
  mockCiYml,
  mockCommitSha,
  mockProjectPath,
  mockProjectNamespace,
} from '../../mock_data';

describe('Pipeline Editor | Text editor component', () => {
  let wrapper;

  let editorReadyListener;
  let mockUse;
  let mockRegisterCiSchema;

  const MockEditorLite = {
    template: '<div/>',
    props: ['value', 'fileName'],
    mounted() {
      this.$emit(EDITOR_READY_EVENT);
    },
    methods: {
      getEditor: () => ({
        use: mockUse,
        registerCiSchema: mockRegisterCiSchema,
      }),
    },
  };

  const createComponent = (glFeatures = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TextEditor, {
      provide: {
        projectPath: mockProjectPath,
        projectNamespace: mockProjectNamespace,
        ciConfigPath: mockCiConfigPath,
        glFeatures,
      },
      attrs: {
        value: mockCiYml,
      },
      // Simulate graphQL client query result
      data() {
        return {
          commitSha: mockCommitSha,
        };
      },
      listeners: {
        [EDITOR_READY_EVENT]: editorReadyListener,
      },
      stubs: {
        EditorLite: MockEditorLite,
      },
    });
  };

  const findEditor = () => wrapper.findComponent(MockEditorLite);

  beforeEach(() => {
    EditorLiteExtension.deferRerender = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();

    mockUse.mockClear();
    mockRegisterCiSchema.mockClear();
  });

  describe('template', () => {
    beforeEach(() => {
      editorReadyListener = jest.fn();
      mockUse = jest.fn();
      mockRegisterCiSchema = jest.fn();

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

    it('bubbles up events', () => {
      findEditor().vm.$emit(EDITOR_READY_EVENT);

      expect(editorReadyListener).toHaveBeenCalled();
    });
  });

  describe('CI schema', () => {
    describe('when `schema_linting` feature flag is on', () => {
      beforeEach(() => {
        createComponent({ schemaLinting: true });
        // Since the editor will have already mounted, the event will have fired.
        // To ensure we properly test this, we clear the mock and re-remit the event.
        mockRegisterCiSchema.mockClear();
        mockUse.mockClear();
        findEditor().vm.$emit(EDITOR_READY_EVENT);
      });

      it('configures editor with syntax highlight', () => {
        expect(mockUse).toHaveBeenCalledTimes(1);
        expect(mockRegisterCiSchema).toHaveBeenCalledTimes(1);
        expect(mockRegisterCiSchema).toHaveBeenCalledWith({
          projectNamespace: mockProjectNamespace,
          projectPath: mockProjectPath,
          ref: mockCommitSha,
        });
      });
    });

    describe('when `schema_linting` feature flag is off', () => {
      beforeEach(() => {
        createComponent();
        findEditor().vm.$emit(EDITOR_READY_EVENT);
      });

      it('does not call the register CI schema function', () => {
        expect(mockUse).not.toHaveBeenCalled();
        expect(mockRegisterCiSchema).not.toHaveBeenCalled();
      });
    });
  });
});
