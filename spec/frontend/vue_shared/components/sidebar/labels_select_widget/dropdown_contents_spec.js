import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import DropdownContents from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents.vue';
import DropdownContentsCreateView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_labels_view.vue';
import DropdownHeader from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_header.vue';
import DropdownFooter from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_footer.vue';

import { mockLabels } from './mock_data';

const showDropdown = jest.fn();

const GlDropdownStub = {
  template: `
    <div data-testid="dropdown">
      <slot name="header"></slot>
      <slot></slot>
      <slot name="footer"></slot>
    </div>
  `,
  methods: {
    show: showDropdown,
    hide: jest.fn(),
  },
};

describe('DropdownContent', () => {
  let wrapper;

  const createComponent = ({ props = {}, data = {} } = {}) => {
    wrapper = shallowMount(DropdownContents, {
      propsData: {
        labelsCreateTitle: 'test',
        selectedLabels: mockLabels,
        allowMultiselect: true,
        labelsListTitle: 'Assign labels',
        footerCreateLabelTitle: 'create',
        footerManageLabelTitle: 'manage',
        dropdownButtonText: 'Labels',
        variant: 'sidebar',
        fullPath: 'test',
        workspaceType: 'project',
        labelCreateType: 'project',
        attrWorkspacePath: 'path',
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
      stubs: {
        GlDropdown: GlDropdownStub,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findCreateView = () => wrapper.findComponent(DropdownContentsCreateView);
  const findLabelsView = () => wrapper.findComponent(DropdownContentsLabelsView);
  const findDropdownHeader = () => wrapper.findComponent(DropdownHeader);
  const findDropdownFooter = () => wrapper.findComponent(DropdownFooter);
  const findDropdown = () => wrapper.findComponent(GlDropdownStub);

  it('calls dropdown `show` method on `isVisible` prop change', async () => {
    createComponent();
    await wrapper.setProps({
      isVisible: true,
    });

    expect(findDropdown().emitted('show')).toBeUndefined();
  });

  it('does not emit `setLabels` event on dropdown hide if labels did not change', () => {
    createComponent();
    findDropdown().vm.$emit('hide');

    expect(wrapper.emitted('setLabels')).toBeUndefined();
  });

  it('emits `setLabels` event on dropdown hide if labels changed on non-sidebar widget', async () => {
    createComponent({ props: { variant: DropdownVariant.Standalone } });
    const updatedLabel = {
      id: 28,
      title: 'Bug',
      description: 'Label for bugs',
      color: '#FF0000',
      textColor: '#FFFFFF',
    };
    findLabelsView().vm.$emit('input', [updatedLabel]);
    await nextTick();
    findDropdown().vm.$emit('hide');

    expect(wrapper.emitted('setLabels')).toEqual([[[updatedLabel]]]);
  });

  it('emits `setLabels` event on visibility change if labels changed on sidebar widget', async () => {
    createComponent({ props: { variant: DropdownVariant.Standalone, isVisible: true } });
    const updatedLabel = {
      id: 28,
      title: 'Bug',
      description: 'Label for bugs',
      color: '#FF0000',
      textColor: '#FFFFFF',
    };
    findLabelsView().vm.$emit('input', [updatedLabel]);
    wrapper.setProps({ isVisible: false });
    await nextTick();

    expect(wrapper.emitted('setLabels')).toEqual([[[updatedLabel]]]);
  });

  it('does not render header on standalone variant', () => {
    createComponent({ props: { variant: DropdownVariant.Standalone } });

    expect(findDropdownHeader().exists()).toBe(false);
  });

  it('renders header on embedded variant', () => {
    createComponent({ props: { variant: DropdownVariant.Embedded } });

    expect(findDropdownHeader().exists()).toBe(true);
  });

  it('renders header on sidebar variant', () => {
    createComponent();

    expect(findDropdownHeader().exists()).toBe(true);
  });

  it('sets searchKey for labels view on input event from header', async () => {
    createComponent();

    expect(wrapper.vm.searchKey).toEqual('');
    findDropdownHeader().vm.$emit('input', '123');
    await nextTick();

    expect(findLabelsView().props('searchKey')).toEqual('123');
  });

  describe('Create view', () => {
    beforeEach(() => {
      createComponent({ data: { showDropdownContentsCreateView: true } });
    });

    it('renders create view when `showDropdownContentsCreateView` prop is `true`', () => {
      expect(findCreateView().exists()).toBe(true);
    });

    it('does not render footer', () => {
      expect(findDropdownFooter().exists()).toBe(false);
    });

    it('changes the view to Labels view on `toggleDropdownContentsCreateView` event', async () => {
      findDropdownHeader().vm.$emit('toggleDropdownContentsCreateView');
      await nextTick();

      expect(findCreateView().exists()).toBe(false);
      expect(findLabelsView().exists()).toBe(true);
    });

    it('changes the view to Labels view on `hideCreateView` event', async () => {
      findCreateView().vm.$emit('hideCreateView');
      await nextTick();

      expect(findCreateView().exists()).toBe(false);
      expect(findLabelsView().exists()).toBe(true);
    });
  });

  describe('Labels view', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders labels view when `showDropdownContentsCreateView` when `showDropdownContentsCreateView` prop is `false`', () => {
      expect(findLabelsView().exists()).toBe(true);
    });

    it('renders footer on sidebar dropdown', () => {
      expect(findDropdownFooter().exists()).toBe(true);
    });

    it('does not render footer on standalone dropdown', () => {
      createComponent({ props: { variant: DropdownVariant.Standalone } });

      expect(findDropdownFooter().exists()).toBe(false);
    });

    it('renders footer on embedded dropdown', () => {
      createComponent({ props: { variant: DropdownVariant.Embedded } });

      expect(findDropdownFooter().exists()).toBe(true);
    });
  });
});
