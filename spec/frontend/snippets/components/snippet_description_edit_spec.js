import SnippetDescriptionEdit from '~/snippets/components/snippet_description_edit.vue';
import { shallowMount } from '@vue/test-utils';

describe('Snippet Description Edit component', () => {
  let wrapper;
  const defaultDescription = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const markdownPreviewPath = 'foo/';
  const markdownDocsPath = 'help/';

  function createComponent(description = defaultDescription) {
    wrapper = shallowMount(SnippetDescriptionEdit, {
      propsData: {
        description,
        markdownPreviewPath,
        markdownDocsPath,
      },
    });
  }

  function isHidden(sel) {
    return wrapper.find(sel).classes('d-none');
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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
});
