import { shallowMount } from '@vue/test-utils';
import { GlKeysetPagination } from '@gitlab/ui';

import TodosPagination, { CURSOR_CHANGED_EVENT } from '~/todos/components/todos_pagination.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { DEFAULT_PAGE_SIZE } from '~/todos/constants';

describe('TodosPagination', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TodosPagination, {
      propsData: {
        hasPreviousPage: true,
        hasNextPage: true,
        startCursor: '',
        endCursor: '',
        ...props,
      },
    });
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findPageSizeSelector = () => wrapper.findComponent(PageSizeSelector);

  beforeEach(() => {
    createComponent();
  });

  it('contains keyset pagination', () => {
    expect(findPagination().exists()).toBe(true);
  });

  it('contains a page size selector', () => {
    expect(findPageSizeSelector().exists()).toBe(true);
  });

  it('sets the default page size', () => {
    expect(findPageSizeSelector().props('value')).toBe(DEFAULT_PAGE_SIZE);
  });

  it('raises a "cursor" event when changing the page size', () => {
    const pageSizeSelector = findPageSizeSelector();
    const newSize = 50;
    pageSizeSelector.vm.$emit('input', newSize);

    expect(wrapper.emitted(CURSOR_CHANGED_EVENT)).toEqual([
      [
        {
          first: 50,
          last: null,
          before: null,
          after: null,
        },
      ],
    ]);
  });

  it('raises a "cursor" event when moving to the next page', () => {
    const pagination = findPagination();
    const newCursor = 'cursor-2';
    pagination.vm.$emit('next', newCursor);

    expect(wrapper.emitted(CURSOR_CHANGED_EVENT)).toEqual([
      [
        {
          first: DEFAULT_PAGE_SIZE,
          after: newCursor,
          last: null,
          before: null,
        },
      ],
    ]);
  });

  it('raises a "cursor" event when moving to the previous page', () => {
    const pagination = findPagination();
    const newCursor = 'cursor-1';
    pagination.vm.$emit('prev', newCursor);

    expect(wrapper.emitted(CURSOR_CHANGED_EVENT)).toEqual([
      [
        {
          first: null,
          after: null,
          last: DEFAULT_PAGE_SIZE,
          before: newCursor,
        },
      ],
    ]);
  });

  it('preserves the page size when moving to the next page', () => {
    const pagination = findPagination();
    const pageSizeSelector = findPageSizeSelector();

    const newSize = 50;
    pageSizeSelector.vm.$emit('input', newSize);

    const newCursor = 'cursor-2';
    pagination.vm.$emit('next', newCursor);

    expect(wrapper.emitted(CURSOR_CHANGED_EVENT)).toContainEqual([
      {
        first: newSize,
        after: newCursor,
        last: null,
        before: null,
      },
    ]);
  });

  it('preserves the page size when moving to the previous page', () => {
    const pagination = findPagination();
    const pageSizeSelector = findPageSizeSelector();

    const newSize = 50;
    pageSizeSelector.vm.$emit('input', newSize);

    const newCursor = 'cursor-1';
    pagination.vm.$emit('prev', newCursor);

    expect(wrapper.emitted(CURSOR_CHANGED_EVENT)).toContainEqual([
      {
        first: null,
        after: null,
        last: newSize,
        before: newCursor,
      },
    ]);
  });

  it('preserves the current page when changing the page size', () => {
    const pagination = findPagination();
    const pageSizeSelector = findPageSizeSelector();

    const newCursor = 'cursor-2';
    pagination.vm.$emit('next', newCursor);

    const newSize = 50;
    pageSizeSelector.vm.$emit('input', newSize);

    expect(wrapper.emitted(CURSOR_CHANGED_EVENT)).toContainEqual([
      {
        first: newSize,
        after: newCursor,
        last: null,
        before: null,
      },
    ]);
  });
});
