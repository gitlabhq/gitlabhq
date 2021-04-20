import { shallowMount } from '@vue/test-utils';
import { EditorContent } from 'tiptap';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import createEditor from '~/content_editor/services/create_editor';
import createMarkdownSerializer from '~/content_editor/services/markdown_serializer';

describe('ContentEditor', () => {
  let wrapper;
  let editor;

  const buildWrapper = async () => {
    editor = await createEditor({ serializer: createMarkdownSerializer({ toHTML: () => '' }) });
    wrapper = shallowMount(ContentEditor, {
      propsData: {
        editor,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders editor content component and attaches editor instance', async () => {
    await buildWrapper();

    expect(wrapper.findComponent(EditorContent).props().editor).toBe(editor);
  });

  it('renders top toolbar component and attaches editor instance', async () => {
    await buildWrapper();

    expect(wrapper.findComponent(TopToolbar).props().editor).toBe(editor);
  });
});
