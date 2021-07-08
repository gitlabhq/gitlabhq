import { GlAlert } from '@gitlab/ui';
import { EditorContent } from '@tiptap/vue-2';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import { createContentEditor } from '~/content_editor/services/create_content_editor';

describe('ContentEditor', () => {
  let wrapper;
  let editor;

  const findEditorElement = () => wrapper.findByTestId('content-editor');
  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  const createWrapper = async (contentEditor) => {
    wrapper = shallowMountExtended(ContentEditor, {
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

    const editorContent = wrapper.findComponent(EditorContent);

    expect(editorContent.props().editor).toBe(editor.tiptapEditor);
    expect(editorContent.classes()).toContain('md');
  });

  it('renders top toolbar component and attaches editor instance', () => {
    createWrapper(editor);

    expect(wrapper.findComponent(TopToolbar).props().contentEditor).toBe(editor);
  });

  it.each`
    isFocused | classes
    ${true}   | ${['md-area', 'is-focused']}
    ${false}  | ${['md-area']}
  `(
    'has $classes class selectors when tiptapEditor.isFocused = $isFocused',
    ({ isFocused, classes }) => {
      editor.tiptapEditor.isFocused = isFocused;
      createWrapper(editor);

      expect(findEditorElement().classes()).toStrictEqual(classes);
    },
  );

  it('adds isFocused class when tiptapEditor is focused', () => {
    editor.tiptapEditor.isFocused = true;
    createWrapper(editor);

    expect(findEditorElement().classes()).toContain('is-focused');
  });

  describe('displaying error', () => {
    const error = 'Content Editor error';

    beforeEach(async () => {
      createWrapper(editor);

      editor.tiptapEditor.emit('error', error);

      await nextTick();
    });

    it('displays error notifications from the tiptap editor', () => {
      expect(findErrorAlert().text()).toBe(error);
    });

    it('allows dismissing an error alert', async () => {
      findErrorAlert().vm.$emit('dismiss');

      await nextTick();

      expect(findErrorAlert().exists()).toBe(false);
    });
  });
});
