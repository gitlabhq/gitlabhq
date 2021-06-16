import { GlPagination } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RunnerPagination from '~/runner/components/runner_pagination.vue';

const mockStartCursor = 'START_CURSOR';
const mockEndCursor = 'END_CURSOR';

describe('RunnerPagination', () => {
  let wrapper;

  const findPagination = () => wrapper.findComponent(GlPagination);

  const createComponent = ({ page = 1, hasPreviousPage = false, hasNextPage = true } = {}) => {
    wrapper = mount(RunnerPagination, {
      propsData: {
        value: {
          page,
        },
        pageInfo: {
          hasPreviousPage,
          hasNextPage,
          startCursor: mockStartCursor,
          endCursor: mockEndCursor,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('When on the first page', () => {
    beforeEach(() => {
      createComponent({
        page: 1,
        hasPreviousPage: false,
        hasNextPage: true,
      });
    });

    it('Contains the current page information', () => {
      expect(findPagination().props('value')).toBe(1);
      expect(findPagination().props('prevPage')).toBe(null);
      expect(findPagination().props('nextPage')).toBe(2);
    });

    it('Shows prev page disabled', () => {
      expect(findPagination().find('[aria-disabled]').text()).toBe('Prev');
    });

    it('Shows next page link', () => {
      expect(findPagination().find('a').text()).toBe('Next');
    });

    it('Goes to the second page', () => {
      findPagination().vm.$emit('input', 2);

      expect(wrapper.emitted('input')[0]).toEqual([
        {
          after: mockEndCursor,
          page: 2,
        },
      ]);
    });
  });

  describe('When in between pages', () => {
    beforeEach(() => {
      createComponent({
        page: 2,
        hasPreviousPage: true,
        hasNextPage: true,
      });
    });

    it('Contains the current page information', () => {
      expect(findPagination().props('value')).toBe(2);
      expect(findPagination().props('prevPage')).toBe(1);
      expect(findPagination().props('nextPage')).toBe(3);
    });

    it('Shows the next and previous pages', () => {
      const links = findPagination().findAll('a');

      expect(links).toHaveLength(2);
      expect(links.at(0).text()).toBe('Prev');
      expect(links.at(1).text()).toBe('Next');
    });

    it('Goes to the last page', () => {
      findPagination().vm.$emit('input', 3);

      expect(wrapper.emitted('input')[0]).toEqual([
        {
          after: mockEndCursor,
          page: 3,
        },
      ]);
    });

    it('Goes to the first page', () => {
      findPagination().vm.$emit('input', 1);

      expect(wrapper.emitted('input')[0]).toEqual([
        {
          before: mockStartCursor,
          page: 1,
        },
      ]);
    });
  });

  describe('When in the last page', () => {
    beforeEach(() => {
      createComponent({
        page: 3,
        hasPreviousPage: true,
        hasNextPage: false,
      });
    });

    it('Contains the current page', () => {
      expect(findPagination().props('value')).toBe(3);
      expect(findPagination().props('prevPage')).toBe(2);
      expect(findPagination().props('nextPage')).toBe(null);
    });

    it('Shows next page link', () => {
      expect(findPagination().find('a').text()).toBe('Prev');
    });

    it('Shows next page disabled', () => {
      expect(findPagination().find('[aria-disabled]').text()).toBe('Next');
    });
  });

  describe('When only one page', () => {
    beforeEach(() => {
      createComponent({
        page: 1,
        hasPreviousPage: false,
        hasNextPage: false,
      });
    });

    it('does not display pagination', () => {
      expect(wrapper.html()).toBe('');
    });

    it('Contains the current page', () => {
      expect(findPagination().props('value')).toBe(1);
    });

    it('Shows no more page buttons', () => {
      expect(findPagination().props('prevPage')).toBe(null);
      expect(findPagination().props('nextPage')).toBe(null);
    });
  });
});
