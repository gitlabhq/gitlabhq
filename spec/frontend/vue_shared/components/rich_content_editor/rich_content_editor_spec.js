import { shallowMount } from '@vue/test-utils';
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';

describe('Rich Content Editor', () => {
  let wrapper;

  const editorOptions = {
    toolbarItems: [
      'heading',
      'bold',
      'italic',
      'strike',
      'divider',
      'quote',
      'link',
      'codeblock',
      'divider',
      'ul',
      'ol',
      'task',
      'divider',
      'hr',
      'table',
      'divider',
      'code',
    ],
  };
  const value = '## Some Markdown';
  const findEditor = () => wrapper.find({ ref: 'editor' });

  beforeEach(() => {
    wrapper = shallowMount(RichContentEditor, {
      propsData: { value },
    });
  });

  describe('when content is loaded', () => {
    it('renders an editor', () => {
      expect(findEditor().exists()).toBe(true);
    });

    it('renders the correct content', () => {
      expect(findEditor().props().initialValue).toBe(value);
    });

    it('provides the correct editor options', () => {
      expect(findEditor().props().options).toEqual(editorOptions);
    });

    it('has the correct initial edit type', () => {
      expect(findEditor().props().initialEditType).toBe('wysiwyg');
    });

    it('has the correct height', () => {
      expect(findEditor().props().height).toBe('100%');
    });
  });

  describe('when content is changed', () => {
    it('emits an input event with the changed content', () => {
      const changedMarkdown = '## Changed Markdown';
      const getMarkdownMock = jest.fn().mockReturnValueOnce(changedMarkdown);

      findEditor().setMethods({ invoke: getMarkdownMock });
      findEditor().vm.$emit('change');

      expect(wrapper.emitted().input[0][0]).toBe(changedMarkdown);
    });
  });
});
