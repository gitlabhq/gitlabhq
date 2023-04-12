import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReferenceLabelWrapper from '~/content_editor/components/wrappers/reference_label.vue';

describe('content/components/wrappers/reference_label', () => {
  let wrapper;

  const createWrapper = (node = {}) => {
    wrapper = shallowMountExtended(ReferenceLabelWrapper, {
      propsData: { node },
    });
  };

  it("renders a GlLabel with the node's text and color", () => {
    createWrapper({ attrs: { color: '#ff0000', text: 'foo bar', originalText: '~"foo bar"' } });

    const glLabel = wrapper.findComponent(GlLabel);

    expect(glLabel.props()).toMatchObject(
      expect.objectContaining({
        title: 'foo bar',
        backgroundColor: '#ff0000',
      }),
    );
  });

  it('renders a scoped label if there is a "::" in the label', () => {
    createWrapper({ attrs: { color: '#ff0000', text: 'foo::bar', originalText: '~"foo::bar"' } });

    expect(wrapper.findComponent(GlLabel).props().scoped).toBe(true);
  });
});
