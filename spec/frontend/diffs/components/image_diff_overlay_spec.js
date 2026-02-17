import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import ImageDiffOverlay from '~/diffs/components/image_diff_overlay.vue';
import BaseImageDiffOverlay from '~/diffs/components/base_image_diff_overlay.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { imageDiffDiscussions } from '../mock_data/diff_discussions';

Vue.use(PiniaVuePlugin);

describe('Diffs image diff overlay component', () => {
  const dimensions = {
    width: 99.9,
    height: 199.5,
  };

  let wrapper;
  let pinia;

  const getBaseOverlay = () => wrapper.findComponent(BaseImageDiffOverlay);

  function createComponent(props = {}) {
    wrapper = shallowMount(ImageDiffOverlay, {
      pinia,
      propsData: {
        discussions: [...imageDiffDiscussions],
        fileHash: 'ABC',
        renderedWidth: 200,
        renderedHeight: 200,
        ...dimensions,
        ...props,
      },
    });
  }

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
  });

  it('renders base image overlay', () => {
    createComponent();
    expect(getBaseOverlay().exists()).toBe(true);
    expect(getBaseOverlay().props()).toMatchObject({
      discussions: [...imageDiffDiscussions],
      canComment: false,
      commentForm: null,
      badgeClass: '',
      shouldToggleDiscussion: true,
      renderedWidth: 200,
      renderedHeight: 200,
      ...dimensions,
    });
  });

  it('always passes discussions as an array', () => {
    createComponent({ discussions: imageDiffDiscussions[0] });
    expect(getBaseOverlay().props('discussions')).toMatchObject([imageDiffDiscussions[0]]);
  });

  it('handles image clicks', () => {
    createComponent();
    getBaseOverlay().vm.$emit('image-click', {});
    expect(useLegacyDiffs().openDiffFileCommentForm).toHaveBeenCalledWith({ fileHash: 'ABC' });
  });

  it('handles pin clicks', () => {
    createComponent();
    getBaseOverlay().vm.$emit('pin-click', {});
    expect(useLegacyDiffs().toggleFileDiscussion).toHaveBeenCalledWith({});
  });
});
