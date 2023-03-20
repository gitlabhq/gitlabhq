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

  function isHidden(sel) {
    return wrapper.find(sel).classes('d-none');
  }

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the field expanded when description exists', () => {
      expect(wrapper.find('.js-collapsed').classes('d-none')).toBe(true);
      expect(wrapper.find('.js-expanded').classes('d-none')).toBe(false);

      expect(isHidden('.js-collapsed')).toBe(true);
      expect(isHidden('.js-expanded')).toBe(false);
    });

    it('renders the field collapsed if there is no description yet', () => {
      createComponent('');

      expect(isHidden('.js-collapsed')).toBe(false);
      expect(isHidden('.js-expanded')).toBe(true);
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
