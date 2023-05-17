import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FootnoteDefinitionWrapper from '~/content_editor/components/wrappers/footnote_definition.vue';

describe('content/components/wrappers/footnote_definition', () => {
  let wrapper;

  const createWrapper = (node = {}) => {
    wrapper = shallowMountExtended(FootnoteDefinitionWrapper, {
      propsData: {
        node,
      },
    });
  };

  it('renders footnote label as a readyonly element', () => {
    const label = 'footnote';

    createWrapper({
      attrs: {
        label,
      },
    });
    expect(wrapper.text()).toContain(label);
    expect(wrapper.findByTestId('footnote-label').attributes().contenteditable).toBe('false');
  });
});
