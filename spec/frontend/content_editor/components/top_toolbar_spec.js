import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import { createContentEditor } from '~/content_editor/services/create_content_editor';

describe('content_editor/components/top_toolbar', () => {
  let wrapper;
  let contentEditor;

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
    buildEditor();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    testId            | buttonProps
    ${'bold'}         | ${{ contentType: 'bold', iconName: 'bold', label: 'Bold text', editorCommand: 'toggleBold' }}
    ${'italic'}       | ${{ contentType: 'italic', iconName: 'italic', label: 'Italic text', editorCommand: 'toggleItalic' }}
    ${'code'}         | ${{ contentType: 'code', iconName: 'code', label: 'Code', editorCommand: 'toggleCode' }}
    ${'blockquote'}   | ${{ contentType: 'blockquote', iconName: 'quote', label: 'Insert a quote', editorCommand: 'toggleBlockquote' }}
    ${'bullet-list'}  | ${{ contentType: 'bulletList', iconName: 'list-bulleted', label: 'Add a bullet list', editorCommand: 'toggleBulletList' }}
    ${'ordered-list'} | ${{ contentType: 'orderedList', iconName: 'list-numbered', label: 'Add a numbered list', editorCommand: 'toggleOrderedList' }}
  `('renders $testId button', ({ testId, buttonProps }) => {
    buildWrapper();
    expect(wrapper.findByTestId(testId).props()).toEqual({
      ...buttonProps,
      tiptapEditor: contentEditor.tiptapEditor,
    });
  });
});
