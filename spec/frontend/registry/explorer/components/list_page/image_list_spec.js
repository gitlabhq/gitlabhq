import { shallowMount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import Component from '~/registry/explorer/components/list_page/image_list.vue';
import ImageListRow from '~/registry/explorer/components/list_page/image_list_row.vue';

import { imagesListResponse, imagePagination } from '../../mock_data';

describe('Image List', () => {
  let wrapper;

  const findRow = () => wrapper.findAll(ImageListRow);
  const findPagination = () => wrapper.find(GlPagination);

  const mountComponent = () => {
    wrapper = shallowMount(Component, {
      propsData: {
        images: imagesListResponse.data,
        pagination: imagePagination,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  describe('list', () => {
    it('contains one list element for each image', () => {
      expect(findRow().length).toBe(imagesListResponse.data.length);
    });

    it('when delete event is emitted on the row it emits up a delete event', () => {
      findRow()
        .at(0)
        .vm.$emit('delete', 'foo');
      expect(wrapper.emitted('delete')).toEqual([['foo']]);
    });
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
