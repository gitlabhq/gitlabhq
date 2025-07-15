import { shallowMount, mount } from '@vue/test-utils';
import SnippetDescriptionEdit from '~/snippets/components/snippet_description_edit.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';

describe('Snippet Description Edit component', () => {
  let wrapper;

  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const mountComponent = ({ description = 'test' } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(SnippetDescriptionEdit, {
      attachTo: document.body,
      propsData: {
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        value: description,
      },
      stubs: {
        MarkdownField,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  describe('rendering', () => {
    it('renders the description field', () => {
      mountComponent({}, mount);

      expect(wrapper.find('.md-area').exists()).toBe(true);
    });
  });

  describe('functionality', () => {
    it('emits "input" event when description is changed', () => {
      expect(wrapper.emitted('input')).toBeUndefined();
      const newDescription = 'dummy';
      findMarkdownEditor().vm.$emit('input', newDescription);

      expect(wrapper.emitted('input')[0]).toEqual([newDescription]);
    });
  });

  it('uses the MarkdownEditor component to edit markdown', () => {
    expect(findMarkdownEditor().props()).toMatchObject({
      value: 'test',
      renderMarkdownPath: '/',
      autofocus: true,
      supportsQuickActions: true,
      markdownDocsPath: '/',
      enableAutocomplete: true,
    });
  });

  it('emits input event when MarkdownEditor emits input event', () => {
    const markdown = 'markdown';

    findMarkdownEditor().vm.$emit('input', markdown);

    expect(wrapper.emitted('input')).toEqual([[markdown]]);
  });
});
