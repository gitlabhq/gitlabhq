import { GlLoadingIcon } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MediaWrapper from '~/content_editor/components/wrappers/media.vue';

describe('content/components/wrappers/media', () => {
  let wrapper;

  const createWrapper = async (nodeAttrs = {}) => {
    wrapper = shallowMountExtended(MediaWrapper, {
      propsData: {
        node: {
          attrs: nodeAttrs,
          type: {
            name: 'image',
          },
        },
      },
    });
  };
  const findMedia = () => wrapper.findByTestId('media');
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

    expect(findMedia().attributes().src).toBe(src);
  });

  describe('when uploading', () => {
    beforeEach(() => {
      createWrapper({ uploading: true });
    });

    it('renders a gl-loading-icon component', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('adds gl-opacity-5 class selector to the media tag', () => {
      expect(findMedia().classes()).toContain('gl-opacity-5');
    });
  });

  describe('when not uploading', () => {
    beforeEach(() => {
      createWrapper({ uploading: false });
    });

    it('does not render a gl-loading-icon component', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not add gl-opacity-5 class selector to the media tag', () => {
      expect(findMedia().classes()).not.toContain('gl-opacity-5');
    });
  });
});
