import { GlTabs, GlTab } from '@gitlab/ui';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FormattingToolbar from '~/content_editor/components/formatting_toolbar.vue';
import CommentTemplatesModal from '~/vue_shared/components/markdown/comment_templates_modal.vue';
import {
  TOOLBAR_CONTROL_TRACKING_ACTION,
  CONTENT_EDITOR_TRACKING_LABEL,
} from '~/content_editor/constants';
import { createTestEditor, mockChainedCommands } from '../test_utils';

describe('content_editor/components/formatting_toolbar', () => {
  let wrapper;
  let trackingSpy;

  const contentEditor = {
    codeSuggestionsConfig: {
      canSuggest: true,
    },
  };

  const buildWrapper = ({ props = {}, provide = { contentEditor } } = {}) => {
    wrapper = shallowMountExtended(FormattingToolbar, {
      stubs: {
        GlTabs,
        GlTab,
      },
      propsData: props,
      provide,
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  describe.each`
    testId               | controlProps
    ${'text-styles'}     | ${{}}
    ${'bold'}            | ${{ contentType: 'bold', iconName: 'bold', label: 'Bold (Ctrl+B)', editorCommand: 'toggleBold' }}
    ${'italic'}          | ${{ contentType: 'italic', iconName: 'italic', label: 'Italic (Ctrl+I)', editorCommand: 'toggleItalic' }}
    ${'strike'}          | ${{ contentType: 'strike', iconName: 'strikethrough', label: 'Strikethrough (Ctrl+Shift+X)', editorCommand: 'toggleStrike' }}
    ${'blockquote'}      | ${{ contentType: 'blockquote', iconName: 'quote', label: 'Insert a quote', editorCommand: 'toggleBlockquote' }}
    ${'code'}            | ${{ contentType: 'code', iconName: 'code', label: 'Code', editorCommand: 'toggleCode' }}
    ${'link'}            | ${{ contentType: 'link', iconName: 'link', label: 'Insert link (Ctrl+K)', editorCommand: 'editLink' }}
    ${'link'}            | ${{}}
    ${'bullet-list'}     | ${{ contentType: 'bulletList', iconName: 'list-bulleted', label: 'Add a bullet list', editorCommand: 'toggleBulletList' }}
    ${'ordered-list'}    | ${{ contentType: 'orderedList', iconName: 'list-numbered', label: 'Add a numbered list', editorCommand: 'toggleOrderedList' }}
    ${'task-list'}       | ${{ contentType: 'taskList', iconName: 'list-task', label: 'Add a checklist', editorCommand: 'toggleTaskList' }}
    ${'code-suggestion'} | ${{ contentType: 'codeSuggestion', iconName: 'doc-code', label: 'Insert suggestion', editorCommand: 'insertCodeSuggestion' }}
    ${'attachment'}      | ${{}}
    ${'table'}           | ${{}}
    ${'more'}            | ${{}}
  `('given a $testId toolbar control', ({ testId, controlProps }) => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders the toolbar control with the provided properties', () => {
      expect(wrapper.findByTestId(testId).exists()).toBe(true);

      Object.keys(controlProps).forEach((propName) => {
        expect(wrapper.findByTestId(testId).props(propName)).toBe(controlProps[propName]);
      });
    });

    it('tracks the execution of toolbar controls', () => {
      const eventData = { contentType: 'blockquote', value: 1 };
      const { contentType, value } = eventData;

      wrapper.findByTestId(testId).vm.$emit('execute', eventData);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, TOOLBAR_CONTROL_TRACKING_ACTION, {
        label: CONTENT_EDITOR_TRACKING_LABEL,
        property: contentType,
        value,
      });
    });
  });

  describe('MacOS shortcuts', () => {
    beforeEach(() => {
      window.gl = { client: { isMac: true } };

      buildWrapper();
    });

    it.each`
      testId      | label
      ${'bold'}   | ${'Bold (⌘B)'}
      ${'italic'} | ${'Italic (⌘I)'}
      ${'strike'} | ${'Strikethrough (⌘⇧X)'}
      ${'link'}   | ${'Insert link (⌘K)'}
    `('shows label $label for $testId', ({ testId, label }) => {
      expect(wrapper.findByTestId(testId).props('label')).toBe(label);
    });
  });

  describe('when attachment button is hidden', () => {
    it('does not show the attachment button', () => {
      buildWrapper({ props: { hideAttachmentButton: true } });

      expect(wrapper.findByTestId('attachment').exists()).toBe(false);
    });
  });

  describe('when selecting a saved reply from the comment templates dropdown', () => {
    it('updates the rich text editor with the saved comment', async () => {
      const tiptapEditor = createTestEditor();

      buildWrapper({
        provide: {
          tiptapEditor,
          contentEditor,
          newCommentTemplatePaths: ['some/path'],
        },
      });

      const commands = mockChainedCommands(tiptapEditor, ['focus', 'pasteContent', 'run']);
      await wrapper.findComponent(CommentTemplatesModal).vm.$emit('select', 'Some saved comment');

      expect(commands.focus).toHaveBeenCalled();
      expect(commands.pasteContent).toHaveBeenCalledWith('Some saved comment');
      expect(commands.run).toHaveBeenCalled();
    });

    it('does not show the saved replies icon if newCommentTemplatePath is not provided', () => {
      buildWrapper();

      expect(wrapper.findComponent(CommentTemplatesModal).exists()).toBe(false);
    });
  });

  it('hides code suggestions icon if the user cannot make suggestions', () => {
    buildWrapper({
      provide: {
        contentEditor: {
          codeSuggestionsConfig: { canSuggest: false },
        },
      },
    });

    expect(wrapper.findByTestId('code-suggestion').exists()).toBe(false);
  });
});
