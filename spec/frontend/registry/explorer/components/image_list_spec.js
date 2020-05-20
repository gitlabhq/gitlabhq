import { shallowMount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import Component from '~/registry/explorer/components/image_list.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { RouterLink } from '../stubs';
import { imagesListResponse, imagePagination } from '../mock_data';

describe('Image List', () => {
  let wrapper;

  const firstElement = imagesListResponse.data[0];

  const findDeleteBtn = () => wrapper.find('[data-testid="deleteImageButton"]');
  const findRowItems = () => wrapper.findAll('[data-testid="rowItem"]');
  const findDetailsLink = () => wrapper.find('[data-testid="detailsLink"]');
  const findClipboardButton = () => wrapper.find(ClipboardButton);
  const findPagination = () => wrapper.find(GlPagination);

  const mountComponent = () => {
    wrapper = shallowMount(Component, {
      stubs: {
        RouterLink,
      },
      propsData: {
        images: imagesListResponse.data,
        pagination: imagePagination,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('contains one list element for each image', () => {
    expect(findRowItems().length).toBe(imagesListResponse.data.length);
  });

  it('contains a link to the details page', () => {
    const link = findDetailsLink();
    expect(link.html()).toContain(firstElement.path);
    expect(link.props('to').name).toBe('details');
  });

  it('contains a clipboard button', () => {
    const button = findClipboardButton();
    expect(button.exists()).toBe(true);
    expect(button.props('text')).toBe(firstElement.location);
    expect(button.props('title')).toBe(firstElement.location);
  });

  it('should be possible to delete a repo', () => {
    const deleteBtn = findDeleteBtn();
    expect(deleteBtn.exists()).toBe(true);
  });

  describe('pagination', () => {
    it('exists', () => {
      expect(findPagination().exists()).toBe(true);
    });

    it('is wired to the correct pagination props', () => {
      const pagination = findPagination();
      expect(pagination.props('perPage')).toBe(imagePagination.perPage);
      expect(pagination.props('totalItems')).toBe(imagePagination.total);
      expect(pagination.props('value')).toBe(imagePagination.page);
    });

    it('emits a pageChange event when the page change', () => {
      wrapper.setData({ currentPage: 2 });
      expect(wrapper.emitted('pageChange')).toEqual([[2]]);
    });
  });
});
