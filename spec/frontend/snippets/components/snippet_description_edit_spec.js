import { shallowMount } from '@vue/test-utils';
import SnippetDescriptionEdit from '~/snippets/components/snippet_description_edit.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

describe('Snippet Description Edit component', () => {
  let wrapper;
  const defaultDescription = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const markdownPreviewPath = 'foo/';
  const markdownDocsPath = 'help/';
  const findTextarea = () => wrapper.find('textarea');

  function createComponent(value = defaultDescription) {
    wrapper = shallowMount(SnippetDescriptionEdit, {
      propsData: {
        value,
        markdownPreviewPath,
        markdownDocsPath,
      },
      stubs: {
        MarkdownField,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the description field', () => {
      createComponent('');

      expect(wrapper.find('.md-area').exists()).toBe(true);
    });
  });

  describe('functionality', () => {
    it('emits "input" event when description is changed', () => {
      expect(wrapper.emitted('input')).toBeUndefined();
      const newDescription = 'dummy';
      findTextarea().setValue(newDescription);

      expect(wrapper.emitted('input')[0]).toEqual([newDescription]);
    });
  });
});
