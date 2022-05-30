import { nextTick } from 'vue';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { shallowMount } from '@vue/test-utils';
import CodeBlockWrapper from '~/content_editor/components/wrappers/code_block.vue';
import codeBlockLanguageLoader from '~/content_editor/services/code_block_language_loader';

jest.mock('~/content_editor/services/code_block_language_loader');

describe('content/components/wrappers/code_block', () => {
  const language = 'yaml';
  let wrapper;
  let updateAttributesFn;

  const createWrapper = async (nodeAttrs = { language }) => {
    updateAttributesFn = jest.fn();

    wrapper = shallowMount(CodeBlockWrapper, {
      propsData: {
        node: {
          attrs: nodeAttrs,
        },
        updateAttributes: updateAttributesFn,
      },
    });
  };

  beforeEach(() => {
    codeBlockLanguageLoader.findOrCreateLanguageBySyntax.mockReturnValue({ syntax: language });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a node-view-wrapper as a pre element', () => {
    createWrapper();

    expect(wrapper.findComponent(NodeViewWrapper).props().as).toBe('pre');
    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('gl-relative');
  });

  it('adds content-editor-code-block class to the pre element', () => {
    createWrapper();
    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('content-editor-code-block');
  });

  it('renders a node-view-content as a code element', () => {
    createWrapper();

    expect(wrapper.findComponent(NodeViewContent).props().as).toBe('code');
  });

  it('renders label indicating that code block is frontmatter', () => {
    createWrapper({ isFrontmatter: true, language });

    const label = wrapper.find('[data-testid="frontmatter-label"]');

    expect(label.text()).toEqual('frontmatter:yaml');
    expect(label.classes()).toEqual(['gl-absolute', 'gl-top-0', 'gl-right-3']);
  });

  it('loads code block’s syntax highlight language', async () => {
    createWrapper();

    expect(codeBlockLanguageLoader.loadLanguage).toHaveBeenCalledWith(language);

    await nextTick();

    expect(updateAttributesFn).toHaveBeenCalledWith({ language });
  });
});
