import { GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import DropdownContents from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents.vue';
import DropdownContentsCreateView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_labels_view.vue';

import { mockLabels } from './mock_data';

describe('DropdownContent', () => {
  let wrapper;

  const createComponent = ({ props = {}, injected = {} } = {}) => {
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
        ...props,
      },
      provide: {
        allowLabelCreate: true,
        labelsManagePath: 'foo/bar',
        ...injected,
      },
      stubs: {
        GlDropdown,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownFooter = () => wrapper.find('[data-testid="dropdown-footer"]');
  const findCreateLabelButton = () => wrapper.find('[data-testid="create-label-button"]');
  const findGoBackButton = () => wrapper.find('[data-testid="go-back-button"]');

  describe('Create view', () => {
    beforeEach(() => {
      wrapper.vm.toggleDropdownContentsCreateView();
    });

    it('renders create view when `showDropdownContentsCreateView` prop is `true`', () => {
      expect(wrapper.findComponent(DropdownContentsCreateView).exists()).toBe(true);
    });

    it('does not render footer', () => {
      expect(findDropdownFooter().exists()).toBe(false);
    });

    it('does not render create label button', () => {
      expect(findCreateLabelButton().exists()).toBe(false);
    });

    it('renders go back button', () => {
      expect(findGoBackButton().exists()).toBe(true);
    });
  });

  describe('Labels view', () => {
    it('renders labels view when `showDropdownContentsCreateView` when `showDropdownContentsCreateView` prop is `false`', () => {
      expect(wrapper.findComponent(DropdownContentsLabelsView).exists()).toBe(true);
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

    it('does not render go back button', () => {
      expect(findGoBackButton().exists()).toBe(false);
    });

    it('does not render create label button if `allowLabelCreate` is false', () => {
      createComponent({ injected: { allowLabelCreate: false } });

      expect(findCreateLabelButton().exists()).toBe(false);
    });

    describe('when `allowLabelCreate` is true', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders create label button', () => {
        expect(findCreateLabelButton().exists()).toBe(true);
      });

      it('triggers `toggleDropdownContent` method on create label button click', () => {
        jest.spyOn(wrapper.vm, 'toggleDropdownContent').mockImplementation(() => {});
        findCreateLabelButton().trigger('click');

        expect(wrapper.vm.toggleDropdownContent).toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('renders component container element with classes `gl-w-full gl-mt-2` and no styles', () => {
      expect(wrapper.attributes('class')).toContain('gl-w-full gl-mt-2');
      expect(wrapper.attributes('style')).toBeUndefined();
    });
  });
});
