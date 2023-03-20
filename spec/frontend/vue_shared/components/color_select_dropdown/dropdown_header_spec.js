import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import DropdownHeader from '~/vue_shared/components/color_select_dropdown/dropdown_header.vue';

const propsData = {
  dropdownTitle: 'Epic color',
};

describe('DropdownHeader', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DropdownHeader, { propsData });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    createComponent();
  });

  it('renders the correct title', () => {
    expect(wrapper.text()).toBe(propsData.dropdownTitle);
  });

  it('renders a close button', () => {
    expect(findButton().attributes('aria-label')).toBe('Close');
  });

  it('emits `closeDropdown` event on button click', () => {
    expect(wrapper.emitted('closeDropdown')).toBeUndefined();
    findButton().vm.$emit('click');

    expect(wrapper.emitted('closeDropdown')).toEqual([[]]);
  });
});
