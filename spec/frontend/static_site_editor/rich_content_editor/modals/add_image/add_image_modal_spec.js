import { GlModal, GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { IMAGE_TABS } from '~/static_site_editor/rich_content_editor/constants';
import AddImageModal from '~/static_site_editor/rich_content_editor/modals/add_image/add_image_modal.vue';
import UploadImageTab from '~/static_site_editor/rich_content_editor/modals/add_image/upload_image_tab.vue';

describe('Add Image Modal', () => {
  let wrapper;
  const propsData = { imageRoot: 'path/to/root/' };

  const findModal = () => wrapper.find(GlModal);
  const findTabs = () => wrapper.find(GlTabs);
  const findUploadImageTab = () => wrapper.find(UploadImageTab);
  const findUrlInput = () => wrapper.find({ ref: 'urlInput' });
  const findDescriptionInput = () => wrapper.find({ ref: 'descriptionInput' });

  beforeEach(() => {
    wrapper = shallowMount(AddImageModal, { propsData });
  });

  describe('when content is loaded', () => {
    it('renders a modal component', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('renders a Tabs component', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders an upload image tab', () => {
      expect(findUploadImageTab().exists()).toBe(true);
    });

    it('renders an input to add an image URL', () => {
      expect(findUrlInput().exists()).toBe(true);
    });

    it('renders an input to add an image description', () => {
      expect(findDescriptionInput().exists()).toBe(true);
    });
  });

  describe('add image', () => {
    describe('Upload', () => {
      it('validates the file', () => {
        const preventDefault = jest.fn();
        const description = 'some description';
        const file = { name: 'some_file.png' };

        wrapper.vm.$refs.uploadImageTab = { validateFile: jest.fn() };
        wrapper.setData({ file, description, tabIndex: IMAGE_TABS.UPLOAD_TAB });

        findModal().vm.$emit('ok', { preventDefault });

        expect(wrapper.vm.$refs.uploadImageTab.validateFile).toHaveBeenCalled();
      });
    });

    describe('URL', () => {
      it('emits an addImage event when a valid URL is specified', () => {
        const preventDefault = jest.fn();
        const mockImage = { imageUrl: '/some/valid/url.png', description: 'some description' };
        wrapper.setData({ ...mockImage, tabIndex: IMAGE_TABS.URL_TAB });

        findModal().vm.$emit('ok', { preventDefault });
        expect(preventDefault).not.toHaveBeenCalled();
        expect(wrapper.emitted('addImage')).toEqual([
          [{ imageUrl: mockImage.imageUrl, altText: mockImage.description }],
        ]);
      });
    });
  });
});
