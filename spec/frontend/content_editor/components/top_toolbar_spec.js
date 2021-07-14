import { shallowMount } from '@vue/test-utils';
import { mockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import {
  TOOLBAR_CONTROL_TRACKING_ACTION,
  CONTENT_EDITOR_TRACKING_LABEL,
} from '~/content_editor/constants';
import { createContentEditor } from '~/content_editor/services/create_content_editor';

describe('content_editor/components/top_toolbar', () => {
  let wrapper;
  let contentEditor;
  let trackingSpy;
  const buildEditor = () => {
    contentEditor = createContentEditor({ renderMarkdown: () => true });
  };

  const buildWrapper = () => {
    wrapper = extendedWrapper(
      shallowMount(TopToolbar, {
        propsData: {
          contentEditor,
        },
      }),
    );
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  beforeEach(() => {
    buildEditor();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    testId               | controlProps
    ${'bold'}            | ${{ contentType: 'bold', iconName: 'bold', label: 'Bold text', editorCommand: 'toggleBold' }}
    ${'italic'}          | ${{ contentType: 'italic', iconName: 'italic', label: 'Italic text', editorCommand: 'toggleItalic' }}
    ${'strike'}          | ${{ contentType: 'strike', iconName: 'strikethrough', label: 'Strikethrough', editorCommand: 'toggleStrike' }}
    ${'code'}            | ${{ contentType: 'code', iconName: 'code', label: 'Code', editorCommand: 'toggleCode' }}
    ${'blockquote'}      | ${{ contentType: 'blockquote', iconName: 'quote', label: 'Insert a quote', editorCommand: 'toggleBlockquote' }}
    ${'bullet-list'}     | ${{ contentType: 'bulletList', iconName: 'list-bulleted', label: 'Add a bullet list', editorCommand: 'toggleBulletList' }}
    ${'ordered-list'}    | ${{ contentType: 'orderedList', iconName: 'list-numbered', label: 'Add a numbered list', editorCommand: 'toggleOrderedList' }}
    ${'horizontal-rule'} | ${{ contentType: 'horizontalRule', iconName: 'dash', label: 'Add a horizontal rule', editorCommand: 'setHorizontalRule' }}
    ${'code-block'}      | ${{ contentType: 'codeBlock', iconName: 'doc-code', label: 'Insert a code block', editorCommand: 'toggleCodeBlock' }}
    ${'text-styles'}     | ${{}}
    ${'link'}            | ${{}}
    ${'image'}           | ${{}}
  `('given a $testId toolbar control', ({ testId, controlProps }) => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders the toolbar control with the provided properties', () => {
      expect(wrapper.findByTestId(testId).props()).toEqual({
        ...controlProps,
        tiptapEditor: contentEditor.tiptapEditor,
      });
    });

    it.each`
      eventData
      ${{ contentType: 'bold' }}
      ${{ contentType: 'blockquote', value: 1 }}
    `('tracks the execution of toolbar controls', ({ eventData }) => {
      const { contentType, value } = eventData;
      wrapper.findByTestId(testId).vm.$emit('execute', eventData);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, TOOLBAR_CONTROL_TRACKING_ACTION, {
        label: CONTENT_EDITOR_TRACKING_LABEL,
        property: contentType,
        value,
      });
    });
  });
});
