import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import AddImageModal from '~/vue_shared/components/rich_content_editor/modals/add_image_modal.vue';

describe('Add Image Modal', () => {
  let wrapper;

  const findModal = () => wrapper.find(GlModal);
  const findUrlInput = () => wrapper.find({ ref: 'urlInput' });
  const findDescriptionInput = () => wrapper.find({ ref: 'descriptionInput' });

  beforeEach(() => {
    wrapper = shallowMount(AddImageModal);
  });

  describe('when content is loaded', () => {
    it('renders a modal component', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('renders an input to add an image URL', () => {
      expect(findUrlInput().exists()).toBe(true);
    });

    it('renders an input to add an image description', () => {
      expect(findDescriptionInput().exists()).toBe(true);
    });
  });

  describe('add image', () => {
    it('emits an addImage event when a valid URL is specified', () => {
      const preventDefault = jest.fn();
      const mockImage = { imageUrl: '/some/valid/url.png', altText: 'some description' };
      wrapper.setData({ ...mockImage });

      findModal().vm.$emit('ok', { preventDefault });
      expect(preventDefault).not.toHaveBeenCalled();
      expect(wrapper.emitted('addImage')).toEqual([[mockImage]]);
    });
  });
});
