import { shallowMount } from '@vue/test-utils';
import { GlKeysetPagination } from '@gitlab/ui';
import { nextTick } from 'vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

import TodosPagination, { CURSOR_CHANGED_EVENT } from '~/todos/components/todos_pagination.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { DEFAULT_PAGE_SIZE } from '~/todos/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('TodosPagination', () => {
  let wrapper;

  useLocalStorageSpy();

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TodosPagination, {
      propsData: {
        hasPreviousPage: true,
        hasNextPage: true,
        startCursor: '',
        endCursor: '',
        ...props,
      },
      stubs: {
        LocalStorageSync,
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

  it('syncs the page size to local storage', async () => {
    const pageSizeSelector = findPageSizeSelector();
    const newSize = 50;

    pageSizeSelector.vm.$emit('input', newSize);
    await nextTick();

    expect(localStorage.setItem).toHaveBeenCalledWith('todos-page-size', newSize.toString());
  });

  it('loads page size from local storage', async () => {
    const savedSize = 5;
    localStorage.setItem('todos-page-size', savedSize.toString());

    createComponent();
    await nextTick();

    expect(findPageSizeSelector().props('value')).toBe(savedSize);
  });
});
