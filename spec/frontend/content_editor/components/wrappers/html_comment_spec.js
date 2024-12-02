import { NodeViewWrapper } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HTMLCommentWrapper from '~/content_editor/components/wrappers/html_comment.vue';

describe('content/components/wrappers/html_comment', () => {
  let wrapper;
  const node = {
    type: { name: 'htmlComment' },
    attrs: { description: 'This is a comment' },
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(HTMLCommentWrapper, {
      propsData: { ...props },
    });
  };

  it('renders a read-only comment description', () => {
    createWrapper({ node });

    expect(wrapper.find('[contenteditable=false]').text()).toBe('This is a comment');
  });

  it('shows a gray dashed border by default', () => {
    createWrapper({ node });

    const classList = wrapper.findComponent(NodeViewWrapper).attributes('class');

    expect(classList).toContain('gl-border-dashed gl-border-default');
    expect(classList).not.toContain('gl-border-solid gl-border-blue-400');
  });

  it('shows a blue focus border when selected', () => {
    createWrapper({ node, selected: true });

    const classList = wrapper.findComponent(NodeViewWrapper).attributes('class');

    expect(classList).toContain('gl-border-solid gl-border-blue-400');
    expect(classList).not.toContain('gl-border-dashed gl-border-default');
  });
});
