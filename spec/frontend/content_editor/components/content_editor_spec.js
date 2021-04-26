import { mount } from '@vue/test-utils';
import { EditorContent } from 'tiptap';
import waitForPromises from 'helpers/wait_for_promises';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import createEditor from '~/content_editor/services/create_editor';

describe('ContentEditor', () => {
  let wrapper;
  let editor;

  const createWrapper = async (_editor) => {
    wrapper = mount(ContentEditor, {
      propsData: {
        editor: _editor,
      },
    });
  };

  beforeEach(async () => {
    editor = await createEditor({ renderMarkdown: () => 'sample text' });
    createWrapper(editor);

    await waitForPromises();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders editor content component and attaches editor instance', async () => {
    expect(wrapper.findComponent(EditorContent).props().editor).toBe(editor);
  });

  it('renders top toolbar component and attaches editor instance', async () => {
    expect(wrapper.findComponent(TopToolbar).props().editor).toBe(editor);
  });
});
