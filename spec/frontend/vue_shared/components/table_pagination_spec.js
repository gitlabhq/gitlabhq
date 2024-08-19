import { GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';

describe('Pagination component', () => {
  let wrapper;
  let spy;

  const mountComponent = (props) => {
    wrapper = shallowMount(TablePagination, {
      propsData: props,
    });
  };

  beforeEach(() => {
    spy = jest.fn();
  });

  describe('render', () => {
    it('should not render anything', () => {
      mountComponent({
        pageInfo: {
          nextPage: NaN,
          page: 1,
          perPage: 20,
          previousPage: NaN,
          total: 15,
          totalPages: 1,
        },
        change: spy,
      });

      expect(wrapper.find('*').exists()).toBe(false);
    });

    it('renders if there is a next page', () => {
      mountComponent({
        pageInfo: {
          nextPage: 2,
          page: 1,
          perPage: 20,
          previousPage: NaN,
          total: 15,
          totalPages: 1,
        },
        change: spy,
      });

      expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
    });

    it('renders if there is a prev page', () => {
      mountComponent({
        pageInfo: {
          nextPage: NaN,
          page: 2,
          perPage: 20,
          previousPage: 1,
          total: 15,
          totalPages: 1,
        },
        change: spy,
      });

      expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
    });
  });

  describe('events', () => {
    it('calls change method when page changes', () => {
      mountComponent({
        pageInfo: {
          nextPage: NaN,
          page: 2,
          perPage: 20,
          previousPage: 1,
          total: 15,
          totalPages: 1,
        },
        change: spy,
      });
      wrapper.findComponent(GlPagination).vm.$emit('input', 3);
      expect(spy).toHaveBeenCalledWith(3);
    });
  });
});
