import { GlLoadingIcon } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImageWrapper from '~/content_editor/components/wrappers/image.vue';

describe('content/components/wrappers/image', () => {
  let wrapper;

  const createWrapper = async (nodeAttrs = {}) => {
    wrapper = shallowMountExtended(ImageWrapper, {
      propsData: {
        node: {
          attrs: nodeAttrs,
        },
      },
    });
  };
  const findImage = () => wrapper.findByTestId('image');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a node-view-wrapper with display-inline-block class', () => {
    createWrapper();

    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('gl-display-inline-block');
  });

  it('renders an image that displays the node src', () => {
    const src = 'foobar.png';

    createWrapper({ src });

    expect(findImage().attributes().src).toBe(src);
  });

  describe('when uploading', () => {
    beforeEach(() => {
      createWrapper({ uploading: true });
    });

    it('renders a gl-loading-icon component', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('adds gl-opacity-5 class selector to image', () => {
      expect(findImage().classes()).toContain('gl-opacity-5');
    });
  });

  describe('when not uploading', () => {
    beforeEach(() => {
      createWrapper({ uploading: false });
    });

    it('does not render a gl-loading-icon component', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not add gl-opacity-5 class selector to image', () => {
      expect(findImage().classes()).not.toContain('gl-opacity-5');
    });
  });
});
