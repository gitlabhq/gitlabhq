import { GlPagination, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('Pagination bar', () => {
  const DEFAULT_PROPS = {
    pageInfo: {
      total: 50,
      totalPages: 3,
      page: 3,
      perPage: 20,
    },
  };
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = mount(PaginationBar, {
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      stubs: { LocalStorageSync: true },
    });
  };

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits set-page event when page is selected', () => {
      const NEXT_PAGE = 3;
      // PaginationLinks uses prop instead of event for handling page change
      // So we go one level deep to test this
      wrapper
        .findComponent(PaginationLinks)
        .findComponent(GlPagination)
        .vm.$emit('input', NEXT_PAGE);
      expect(wrapper.emitted('set-page')).toEqual([[NEXT_PAGE]]);
    });

    it('emits set-page-size event when page size is selected', () => {
      const firstItemInPageSizeDropdown = wrapper.findComponent(GlDisclosureDropdownItem);
      firstItemInPageSizeDropdown.vm.$emit('action');

      const [emittedPageSizeChange] = wrapper.emitted('set-page-size')[0];
      expect(firstItemInPageSizeDropdown.text()).toMatchInterpolatedText(
        `${emittedPageSizeChange} items per page`,
      );
    });
  });

  it('renders current page size', () => {
    const CURRENT_PAGE_SIZE = 40;

    createComponent({
      pageInfo: {
        ...DEFAULT_PROPS.pageInfo,
        perPage: CURRENT_PAGE_SIZE,
      },
    });

    expect(
      wrapper.findComponent(GlDisclosureDropdown).find('button').text(),
    ).toMatchInterpolatedText(`${CURRENT_PAGE_SIZE} items per page`);
  });

  it('renders current page information', () => {
    createComponent();

    expect(wrapper.find('[data-testid="information"]').text()).toMatchInterpolatedText(
      'Showing 41 - 50 of 50',
    );
  });

  it('renders current page information when total count is over 1000', () => {
    createComponent({
      pageInfo: {
        ...DEFAULT_PROPS.pageInfo,
        total: 1200,
        page: 2,
      },
    });

    expect(wrapper.find('[data-testid="information"]').text()).toMatchInterpolatedText(
      'Showing 21 - 40 of 1000+',
    );
  });

  describe('local storage sync', () => {
    it('does not perform local storage sync when no storage key is provided', () => {
      createComponent();

      expect(wrapper.findComponent(LocalStorageSync).exists()).toBe(false);
    });

    it('passes current page size to local storage sync when storage key is provided', () => {
      const STORAGE_KEY = 'fakeStorageKey';
      createComponent({ storageKey: STORAGE_KEY });

      expect(wrapper.getComponent(LocalStorageSync).props('storageKey')).toBe(STORAGE_KEY);
    });

    it('emits set-page event when local storage sync provides new value', () => {
      const SAVED_SIZE = 50;
      createComponent({ storageKey: 'some storage key' });

      wrapper.getComponent(LocalStorageSync).vm.$emit('input', SAVED_SIZE);

      expect(wrapper.emitted('set-page-size')).toEqual([[SAVED_SIZE]]);
    });
  });
});
