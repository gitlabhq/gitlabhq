import { shallowMount } from '@vue/test-utils';
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';

describe('Rich Content Editor', () => {
  let wrapper;

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
