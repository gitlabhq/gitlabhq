import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { DROPDOWN_VARIANT } from '~/vue_shared/components/color_select_dropdown/constants';
import DropdownContents from '~/vue_shared/components/color_select_dropdown/dropdown_contents.vue';
import DropdownContentsColorView from '~/vue_shared/components/color_select_dropdown/dropdown_contents_color_view.vue';

import { color } from './mock_data';

const showDropdown = jest.fn();
const focusInput = jest.fn();

const defaultProps = {
  dropdownTitle: '',
  selectedColor: color,
  dropdownButtonText: '',
  variant: '',
  isVisible: false,
};

const GlDropdownStub = {
  template: `
    <div>
      <slot name="header"></slot>
      <slot></slot>
    </div>
  `,
  methods: {
    show: showDropdown,
    hide: jest.fn(),
  },
};

const DropdownHeaderStub = {
  template: `
    <div>Hello, I am a header</div>
  `,
  methods: {
    focusInput,
  },
};

describe('DropdownContent', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(DropdownContents, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      stubs: {
        GlDropdown: GlDropdownStub,
        DropdownHeader: DropdownHeaderStub,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findColorView = () => wrapper.findComponent(DropdownContentsColorView);
  const findDropdownHeader = () => wrapper.findComponent(DropdownHeaderStub);
  const findDropdown = () => wrapper.findComponent(GlDropdownStub);

  it('calls dropdown `show` method on `isVisible` prop change', async () => {
    createComponent();
    await wrapper.setProps({
      isVisible: true,
    });

    expect(showDropdown).toHaveBeenCalledTimes(1);
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
});
