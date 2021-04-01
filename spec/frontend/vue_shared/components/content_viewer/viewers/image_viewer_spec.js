import { shallowMount } from '@vue/test-utils';
import { GREEN_BOX_IMAGE_URL, DUMMY_IMAGE_BLOB_PATH } from 'spec/test_constants';
import ImageViewer from '~/vue_shared/components/content_viewer/viewers/image_viewer.vue';

describe('Image Viewer', () => {
  let wrapper;

  it('renders image preview', () => {
    wrapper = shallowMount(ImageViewer, {
      propsData: { path: GREEN_BOX_IMAGE_URL, fileSize: 1024 },
    });

    expect(wrapper.find('img').element).toHaveAttr('src', GREEN_BOX_IMAGE_URL);
  });

  describe('file sizes', () => {
    it.each`
      fileSize | renderInfo | elementExists | humanizedFileSize
      ${1024}  | ${true}    | ${true}       | ${'1.00 KiB'}
      ${0}     | ${true}    | ${true}       | ${''}
      ${1024}  | ${false}   | ${false}      | ${undefined}
    `(
      'shows file size as "$humanizedFileSize", if fileSize=$fileSize and renderInfo=$renderInfo',
      ({ fileSize, renderInfo, elementExists, humanizedFileSize }) => {
        wrapper = shallowMount(ImageViewer, {
          propsData: { path: GREEN_BOX_IMAGE_URL, fileSize, renderInfo },
        });

        const imageInfo = wrapper.find('.image-info');

        expect(imageInfo.exists()).toBe(elementExists);
        expect(imageInfo.element?.textContent.trim()).toBe(humanizedFileSize);
      },
    );
  });

  describe('file path', () => {
    it('should output a valid URL path for the image', () => {
      wrapper = shallowMount(ImageViewer, {
        propsData: { path: '/url/hello#1.jpg' },
      });

      expect(wrapper.find('img').attributes('src')).toBe('/url/hello%231.jpg');
    });
    it('outputs path without transformations when outputting a Blob', () => {
      const file = new File([], DUMMY_IMAGE_BLOB_PATH);
      const path = window.URL.createObjectURL(file);
      wrapper = shallowMount(ImageViewer, {
        propsData: { path },
      });
      expect(wrapper.find('img').attributes('src')).toBe(path);
    });
  });
});
