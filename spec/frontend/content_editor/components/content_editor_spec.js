import { EditorContent } from '@tiptap/vue-2';
import { shallowMount } from '@vue/test-utils';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import { createContentEditor } from '~/content_editor/services/create_content_editor';

describe('ContentEditor', () => {
  let wrapper;
  let editor;

  const createWrapper = async (contentEditor) => {
    wrapper = shallowMount(ContentEditor, {
      propsData: {
        contentEditor,
      },
    });
  };

  beforeEach(() => {
    editor = createContentEditor({ renderMarkdown: () => true });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders editor content component and attaches editor instance', () => {
    createWrapper(editor);

    expect(wrapper.findComponent(EditorContent).props().editor).toBe(editor.tiptapEditor);
  });

  it('renders top toolbar component and attaches editor instance', () => {
    createWrapper(editor);

    expect(wrapper.findComponent(TopToolbar).props().contentEditor).toBe(editor);
  });

  it.each`
    isFocused | classes
    ${true}   | ${['md', 'md-area', 'is-focused']}
    ${false}  | ${['md', 'md-area']}
  `(
    'has $classes class selectors when tiptapEditor.isFocused = $isFocused',
    ({ isFocused, classes }) => {
      editor.tiptapEditor.isFocused = isFocused;
      createWrapper(editor);

      expect(wrapper.classes()).toStrictEqual(classes);
    },
  );

  it('adds isFocused class when tiptapEditor is focused', () => {
    editor.tiptapEditor.isFocused = true;
    createWrapper(editor);

    expect(wrapper.classes()).toContain('is-focused');
  });
});
