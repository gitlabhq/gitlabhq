import { nextTick } from 'vue';
import { GlDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { DROPDOWN_VARIANT } from '~/vue_shared/components/color_select_dropdown/constants';
import DropdownContents from '~/vue_shared/components/color_select_dropdown/dropdown_contents.vue';
import DropdownContentsColorView from '~/vue_shared/components/color_select_dropdown/dropdown_contents_color_view.vue';
import DropdownHeader from '~/vue_shared/components/color_select_dropdown/dropdown_header.vue';

import { color } from './mock_data';

const defaultProps = {
  dropdownTitle: '',
  selectedColor: color,
  dropdownButtonText: 'Pick a color',
  variant: '',
  isVisible: false,
};

describe('DropdownContent', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(DropdownContents, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
    });
  };

  const findColorView = () => wrapper.findComponent(DropdownContentsColorView);
  const findDropdownHeader = () => wrapper.findComponent(DropdownHeader);
  const findDropdown = () => wrapper.findComponent(GlDropdown);

  it('calls dropdown `show` method on `isVisible` prop change', async () => {
    createComponent();
    const spy = jest.spyOn(wrapper.vm.$refs.dropdown, 'show');
    await wrapper.setProps({
      isVisible: true,
    });

    expect(spy).toHaveBeenCalledTimes(1);
  });

  it('does not emit `setColor` event on dropdown hide if color did not change', () => {
    createComponent();
    findDropdown().vm.$emit('hide');

    expect(wrapper.emitted('setColor')).toBeUndefined();
  });

  it('emits `setColor` event on dropdown hide if color changed on non-sidebar widget', async () => {
    createComponent({ propsData: { variant: DROPDOWN_VARIANT.Embedded } });
    const updatedColor = {
      title: 'Blue-gray',
      color: '#6699cc',
    };
    findColorView().vm.$emit('input', updatedColor);
    await nextTick();
    findDropdown().vm.$emit('hide');

    expect(wrapper.emitted('setColor')).toEqual([[updatedColor]]);
  });

  it('emits `setColor` event on visibility change if color changed on sidebar widget', async () => {
    createComponent({ propsData: { variant: DROPDOWN_VARIANT.Sidebar, isVisible: true } });
    const updatedColor = {
      title: 'Blue-gray',
      color: '#6699cc',
    };
    findColorView().vm.$emit('input', updatedColor);
    wrapper.setProps({ isVisible: false });
    await nextTick();

    expect(wrapper.emitted('setColor')).toEqual([[updatedColor]]);
  });

  it('renders header', () => {
    createComponent();

    expect(findDropdownHeader().exists()).toBe(true);
  });

  it('handles no selected color', () => {
    createComponent({ propsData: { selectedColor: {} } });

    expect(wrapper.findByTestId('fallback-button-text').text()).toEqual(
      defaultProps.dropdownButtonText,
    );
  });
});
