import { shallowMount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import AssigneesDropdown from '~/vue_shared/components/sidebar/assignees_dropdown.vue';

describe('AssigneesDropdown Component', () => {
  it('renders items slot', () => {
    const wrapper = shallowMount(AssigneesDropdown, {
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
});
