import { shallowMount } from '@vue/test-utils';
import { EditorContent } from 'tiptap';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import createEditor from '~/content_editor/services/create_editor';

jest.mock('~/content_editor/services/create_editor');

describe('ContentEditor', () => {
  let wrapper;

  const buildWrapper = () => {
    wrapper = shallowMount(ContentEditor);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders editor content component and attaches editor instance', () => {
    const editor = {};

    createEditor.mockReturnValueOnce(editor);
    buildWrapper();
    expect(wrapper.findComponent(EditorContent).props().editor).toBe(editor);
  });
});
