import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LabelWrapper from '~/content_editor/components/wrappers/label.vue';

describe('content/components/wrappers/label', () => {
  let wrapper;

  const createWrapper = async (node = {}) => {
    wrapper = shallowMountExtended(LabelWrapper, {
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
