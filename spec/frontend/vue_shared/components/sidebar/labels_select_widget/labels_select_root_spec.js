import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import DropdownContents from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents.vue';
import DropdownValue from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_value.vue';
import DropdownValueCollapsed from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_value_collapsed.vue';
import LabelsSelectRoot from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';

import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_widget/store';

import { mockConfig } from './mock_data';

jest.mock('~/lib/utils/common_utils', () => ({
  isInViewport: jest.fn().mockReturnValue(true),
}));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('LabelsSelectRoot', () => {
  let wrapper;
  let store;

  const createComponent = (config = mockConfig, slots = {}) => {
    wrapper = shallowMount(LabelsSelectRoot, {
      localVue,
      slots,
      store,
      propsData: config,
      stubs: {
        DropdownContents,
        SidebarEditableItem,
      },
      provide: {
        iid: '1',
        projectPath: 'test',
        canUpdate: true,
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store(labelsSelectModule());
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders component with classes `labels-select-wrapper position-relative`', () => {
    createComponent();
    expect(wrapper.classes()).toEqual(['labels-select-wrapper', 'position-relative']);
  });

  it.each`
    variant         | cssClass
    ${'standalone'} | ${'is-standalone'}
    ${'embedded'}   | ${'is-embedded'}
  `(
    'renders component root element with CSS class `$cssClass` when `state.variant` is "$variant"',
    ({ variant, cssClass }) => {
      createComponent({
        ...mockConfig,
        variant,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.classes()).toContain(cssClass);
      });
    },
  );

  it('renders `dropdown-value-collapsed` component when `allowLabelCreate` prop is `true`', async () => {
    createComponent();
    await wrapper.vm.$nextTick;
    expect(wrapper.find(DropdownValueCollapsed).exists()).toBe(true);
  });

  it('renders `dropdown-value` component', async () => {
    createComponent(mockConfig, {
      default: 'None',
    });
    await wrapper.vm.$nextTick;

    const valueComp = wrapper.find(DropdownValue);

    expect(valueComp.exists()).toBe(true);
    expect(valueComp.text()).toBe('None');
  });
});
