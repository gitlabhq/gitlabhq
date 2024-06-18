import { GlPagination } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import {
  PREV,
  NEXT,
  LABEL_FIRST_PAGE,
  LABEL_PREV_PAGE,
  LABEL_NEXT_PAGE,
  LABEL_LAST_PAGE,
} from '~/vue_shared/components/pagination/constants';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';

describe('Pagination links component', () => {
  const translations = {
    prevText: PREV,
    nextText: NEXT,
    labelFirstPage: LABEL_FIRST_PAGE,
    labelPrevPage: LABEL_PREV_PAGE,
    labelNextPage: LABEL_NEXT_PAGE,
    labelLastPage: LABEL_LAST_PAGE,
  };

  let wrapper;

  const defaultPropsData = {
    change: jest.fn(),
    pageInfo: {
      page: 3,
      perPage: 5,
      total: 30,
    },
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mount(PaginationLinks, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findGlPagination = () => wrapper.findComponent(GlPagination);

  it('sets `GlPagination` translation props', () => {
    createComponent();

    expect(findGlPagination().props()).toMatchObject(translations);
  });

  describe('when page is changed', () => {
    beforeEach(() => {
      createComponent();
      findGlPagination().vm.$emit('input');
    });

    it('calls `change` prop', () => {
      expect(defaultPropsData.change).toHaveBeenCalled();
    });
  });

  it('sets `GlPagination` `value` prop', () => {
    createComponent();
    expect(findGlPagination().props('value')).toBe(defaultPropsData.pageInfo.page);
  });

  describe('when total is available from page info', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets `GlPagination` `totalItems` and `perPage` props', () => {
      expect(findGlPagination().props()).toMatchObject({
        totalItems: defaultPropsData.pageInfo.total,
        perPage: defaultPropsData.pageInfo.perPage,
      });
    });
  });

  describe('when `total` is not available from page info', () => {
    const pageInfo = {
      page: 3,
      nextPage: 4,
      previousPage: 2,
    };

    beforeEach(() => {
      createComponent({
        propsData: {
          pageInfo,
        },
      });
    });

    it('sets `GlPagination` `nextPage` and `prevPage` props', () => {
      expect(findGlPagination().props()).toMatchObject({
        nextPage: pageInfo.nextPage,
        prevPage: pageInfo.previousPage,
      });
    });
  });
});
