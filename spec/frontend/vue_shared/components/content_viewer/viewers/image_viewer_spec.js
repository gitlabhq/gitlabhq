import { shallowMount } from '@vue/test-utils';

import { GREEN_BOX_IMAGE_URL } from 'spec/test_constants';
import ImageViewer from '~/vue_shared/components/content_viewer/viewers/image_viewer.vue';

describe('Image Viewer', () => {
  const requiredProps = {
    path: GREEN_BOX_IMAGE_URL,
    renderInfo: true,
  };
  let wrapper;
  let imageInfo;

  function createElement({ props, includeRequired = true } = {}) {
    const data = includeRequired ? { ...requiredProps, ...props } : { ...props };

    wrapper = shallowMount(ImageViewer, {
      propsData: data,
    });
    imageInfo = wrapper.find('.image-info');
  }

  describe('file sizes', () => {
    it('should show the humanized file size when `renderInfo` is true and there is size info', () => {
      createElement({ props: { fileSize: 1024 } });

      expect(imageInfo.text()).toContain('1.00 KiB');
    });

    it('should not show the humanized file size when `renderInfo` is true and there is no size', () => {
      const FILESIZE_RE = /\d+(\.\d+)?\s*([KMGTP]i)*B/;

      createElement({ props: { fileSize: 0 } });

      // It shouldn't show any filesize info
      expect(imageInfo.text()).not.toMatch(FILESIZE_RE);
    });

    it('should not show any image information when `renderInfo` is false', () => {
      createElement({ props: { renderInfo: false } });

      expect(imageInfo.exists()).toBe(false);
    });
  });
});
