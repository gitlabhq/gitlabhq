import { GlKeysetPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerPagination from '~/ci/runner/components/runner_pagination.vue';

const mockStartCursor = 'START_CURSOR';
const mockEndCursor = 'END_CURSOR';

describe('RunnerPagination', () => {
  let wrapper;

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(RunnerPagination, {
      propsData,
    });
  };

  describe('When in between pages', () => {
    const mockPageInfo = {
      startCursor: mockStartCursor,
      endCursor: mockEndCursor,
      hasPreviousPage: true,
      hasNextPage: true,
    };

    beforeEach(() => {
      createComponent({
        pageInfo: mockPageInfo,
      });
    });

    it('Contains the current page information', () => {
      expect(findPagination().props()).toMatchObject(mockPageInfo);
    });

    it('Goes to the prev page', () => {
      findPagination().vm.$emit('prev');

      expect(wrapper.emitted('input')[0]).toEqual([
        {
          before: mockStartCursor,
        },
      ]);
    });

    it('Goes to the next page', () => {
      findPagination().vm.$emit('next');

      expect(wrapper.emitted('input')[0]).toEqual([
        {
          after: mockEndCursor,
        },
      ]);
    });
  });

  describe.each`
    page       | hasPreviousPage | hasNextPage
    ${'first'} | ${false}        | ${true}
    ${'last'}  | ${true}         | ${false}
  `('When on the $page page', ({ page, hasPreviousPage, hasNextPage }) => {
    const mockPageInfo = {
      startCursor: mockStartCursor,
      endCursor: mockEndCursor,
      hasPreviousPage,
      hasNextPage,
    };

    beforeEach(() => {
      createComponent({
        pageInfo: mockPageInfo,
      });
    });

    it(`Contains the ${page} page information`, () => {
      expect(findPagination().props()).toMatchObject(mockPageInfo);
    });
  });

  describe('When no other pages', () => {
    beforeEach(() => {
      createComponent({
        pageInfo: {
          hasPreviousPage: false,
          hasNextPage: false,
        },
      });
    });

    it('is not shown', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('When adding more attributes', () => {
    beforeEach(() => {
      createComponent({
        pageInfo: {
          hasPreviousPage: true,
          hasNextPage: false,
        },
        disabled: true,
      });
    });

    it('attributes are passed', () => {
      expect(findPagination().props('disabled')).toBe(true);
    });
  });
});
