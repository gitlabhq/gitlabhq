import { shallowMount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import MultiSelectDropdown from '~/vue_shared/components/sidebar/multiselect_dropdown.vue';

describe('MultiSelectDropdown Component', () => {
  it('renders items slot', () => {
    const wrapper = shallowMount(MultiSelectDropdown, {
      propsData: {
        text: '',
        headerText: '',
      },
      slots: {
        items: '<p>Test</p>',
      },
    });
    expect(getByText(wrapper.element, 'Test')).toBeDefined();
  });

  it('renders search slot', () => {
    const wrapper = shallowMount(MultiSelectDropdown, {
      propsData: {
        text: '',
        headerText: '',
      },
      slots: {
        search: '<p>Search</p>',
      },
    });
    expect(getByText(wrapper.element, 'Search')).toBeDefined();
  });
});
