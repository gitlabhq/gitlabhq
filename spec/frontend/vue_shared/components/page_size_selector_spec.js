import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PageSizeSelector, { PAGE_SIZES } from '~/vue_shared/components/page_size_selector.vue';

describe('Page size selector component', () => {
  let wrapper;

  const createWrapper = ({ pageSize = 20 } = {}) => {
    wrapper = shallowMount(PageSizeSelector, {
      propsData: { value: pageSize },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  it.each(PAGE_SIZES)('shows expected text in the dropdown button for page size %s', (pageSize) => {
    createWrapper({ pageSize });

    expect(findDropdown().props('text')).toBe(`Show ${pageSize} items`);
  });

  it('shows the expected dropdown items', () => {
    createWrapper();

    PAGE_SIZES.forEach((pageSize, index) => {
      expect(findDropdownItems().at(index).text()).toBe(`Show ${pageSize} items`);
    });
  });

  it('will emit the new page size when a dropdown item is clicked', () => {
    createWrapper();

    findDropdownItems().wrappers.forEach((itemWrapper, index) => {
      itemWrapper.vm.$emit('click');

      expect(wrapper.emitted('input')[index][0]).toBe(PAGE_SIZES[index]);
    });
  });
});
