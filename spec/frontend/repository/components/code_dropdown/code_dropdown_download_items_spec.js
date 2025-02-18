import { shallowMount } from '@vue/test-utils';
import { GlButton, GlButtonGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import CodeDropdownDownloadItems from '~/repository/components/code_dropdown/code_dropdown_download_items.vue';

describe('CodeDropdownDownloadItem', () => {
  let wrapper;

  const items = [
    { text: 'Download 1', href: '/download1' },
    { text: 'Download 2', href: '/download2' },
  ];

  const findAllGlButtons = () => wrapper.findAllComponents(GlButton);
  const findGlButtonAtIndex = (index) => findAllGlButtons().at(index);
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);

  const createComponent = (props = { items }) => {
    wrapper = shallowMount(CodeDropdownDownloadItems, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders correctly', () => {
    expect(wrapper.exists()).toBe(true);
    expect(findDropdownItem().exists()).toBe(true);
    expect(findButtonGroup().exists()).toBe(true);
  });

  it('does not render when items prop is an empty array', () => {
    createComponent({ items: [] });
    expect(wrapper.exists()).toBe(true);
    expect(findDropdownItem().exists()).toBe(false);
    expect(findButtonGroup().exists()).toBe(false);
  });

  it('renders a button with correct props', () => {
    expect(findAllGlButtons()).toHaveLength(2);

    const firstButton = findGlButtonAtIndex(0);
    expect(firstButton.text()).toBe('Download 1');
    expect(firstButton.attributes('href')).toBe('/download1');

    const secondButton = findGlButtonAtIndex(1);
    expect(secondButton.text()).toBe('Download 2');
    expect(secondButton.attributes('href')).toBe('/download2');
  });

  it('closes the dropdown on click', () => {
    findGlButtonAtIndex(0).vm.$emit('click');
    expect(wrapper.emitted('close-dropdown')).toStrictEqual([[]]);
  });
});
