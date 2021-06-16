import { shallowMount } from '@vue/test-utils';
import UploadImageTab from '~/static_site_editor/rich_content_editor/modals/add_image/upload_image_tab.vue';

describe('Upload Image Tab', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(UploadImageTab);
  });

  afterEach(() => wrapper.destroy());

  const triggerInputEvent = (size) => {
    const file = { size, name: 'file-name.png' };
    const mockEvent = new Event('input');

    Object.defineProperty(mockEvent, 'target', { value: { files: [file] } });

    wrapper.find({ ref: 'fileInput' }).element.dispatchEvent(mockEvent);

    return file;
  };

  describe('onInput', () => {
    it.each`
      size          | fileError
      ${2000000000} | ${'Maximum file size is 2MB. Please select a smaller file.'}
      ${200}        | ${null}
    `('validates the file correctly', ({ size, fileError }) => {
      triggerInputEvent(size);

      expect(wrapper.vm.fileError).toBe(fileError);
    });
  });

  it('emits input event when file is valid', () => {
    const file = triggerInputEvent(200);

    expect(wrapper.emitted('input')).toEqual([[file]]);
  });
});
