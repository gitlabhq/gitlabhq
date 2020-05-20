import { mount } from '@vue/test-utils';
import { GREEN_BOX_IMAGE_URL } from 'spec/test_constants';
import ImageViewer from '~/vue_shared/components/content_viewer/viewers/image_viewer.vue';

describe('Image Viewer', () => {
  let wrapper;

  it('renders image preview', () => {
    wrapper = mount(ImageViewer, {
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
        wrapper = mount(ImageViewer, {
          propsData: { path: GREEN_BOX_IMAGE_URL, fileSize, renderInfo },
        });

        const imageInfo = wrapper.find('.image-info');

        expect(imageInfo.exists()).toBe(elementExists);
        expect(imageInfo.element?.textContent.trim()).toBe(humanizedFileSize);
      },
    );
  });
});
