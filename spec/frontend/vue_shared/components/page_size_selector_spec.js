import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PageSizeSelector, { PAGE_SIZES } from '~/vue_shared/components/page_size_selector.vue';

describe('Page size selector component', () => {
  let wrapper;

  const createWrapper = ({ pageSize = 20, excludePageSizes = [] } = {}) => {
    wrapper = shallowMount(PageSizeSelector, {
      propsData: { value: pageSize, excludePageSizes },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  it.each(PAGE_SIZES)('shows expected text in the listbox button for page size %s', (pageSize) => {
    createWrapper({ pageSize: pageSize.value });

    expect(findListbox().props('toggleText')).toBe(`Show ${pageSize.value} items`);
  });

  it('shows the expected listbox items', () => {
    createWrapper();

    const options = findListbox().props('items');

    PAGE_SIZES.forEach((pageSize, index) => {
      expect(options[index].text).toBe(pageSize.text);
    });
  });

  it('will emit the new page size when a listbox item is clicked', () => {
    createWrapper();

    PAGE_SIZES.forEach((pageSize, index) => {
      findListbox().vm.$emit('select', pageSize.value);
      expect(wrapper.emitted('input')[index][0]).toBe(PAGE_SIZES[index].value);
    });
  });

  describe('when excludePageSizes is set', () => {
    it.each([
      [100, 20],
      [50, 20],
      [20, 100],
    ])('does not show page size %s item', (excludedPageSize, selectedPageSize) => {
      createWrapper({ excludePageSizes: [excludedPageSize], pageSize: selectedPageSize });

      expect(
        findListbox()
          .props('items')
          .map((option) => option.value),
      ).not.toContain(excludedPageSize);
    });
  });
});
