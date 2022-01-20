import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { shallowMount } from '@vue/test-utils';
import FrontmatterWrapper from '~/content_editor/components/wrappers/frontmatter.vue';

describe('content/components/wrappers/frontmatter', () => {
  let wrapper;

  const createWrapper = async (nodeAttrs = { language: 'yaml' }) => {
    wrapper = shallowMount(FrontmatterWrapper, {
      propsData: {
        node: {
          attrs: nodeAttrs,
        },
      },
    });
  };

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
    createWrapper();

    const label = wrapper.find('[data-testid="frontmatter-label"]');

    expect(label.text()).toEqual('frontmatter:yaml');
    expect(label.classes()).toEqual(['gl-absolute', 'gl-top-0', 'gl-right-3']);
  });
});
