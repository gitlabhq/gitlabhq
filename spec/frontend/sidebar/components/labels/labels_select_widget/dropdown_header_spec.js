import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DropdownHeader from '~/sidebar/components/labels/labels_select_widget/dropdown_header.vue';

describe('DropdownHeader', () => {
  let wrapper;

  const createComponent = ({
    showDropdownContentsCreateView = false,
    labelsFetchInProgress = false,
    isStandalone = false,
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(DropdownHeader, {
        propsData: {
          showDropdownContentsCreateView,
          labelsFetchInProgress,
          labelsCreateTitle: 'Create label',
          labelsListTitle: 'Select label',
          searchKey: '',
          isStandalone,
        },
        stubs: {
          GlSearchBoxByType,
        },
      }),
    );
  };

  const findSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findGoBackButton = () => wrapper.findByTestId('go-back-button');
  const findDropdownTitle = () => wrapper.findByTestId('dropdown-header-title');

  beforeEach(() => {
    createComponent();
  });

  describe('Create view', () => {
    beforeEach(() => {
      createComponent({ showDropdownContentsCreateView: true });
    });

    it('renders go back button', () => {
      expect(findGoBackButton().exists()).toBe(true);
    });

    it('does not render search input field', () => {
      expect(findSearchInput().exists()).toBe(false);
    });
  });

  describe('Labels view', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render go back button', () => {
      expect(findGoBackButton().exists()).toBe(false);
    });

    it.each`
      labelsFetchInProgress | disabled
      ${true}               | ${true}
      ${false}              | ${false}
    `(
      'when labelsFetchInProgress is $labelsFetchInProgress, renders search input with disabled prop to $disabled',
      ({ labelsFetchInProgress, disabled }) => {
        createComponent({ labelsFetchInProgress });
        expect(findSearchInput().props('disabled')).toBe(disabled);
      },
    );
  });

  describe('Standalone variant', () => {
    beforeEach(() => {
      createComponent({ isStandalone: true });
    });

    it('renders search input', () => {
      expect(findSearchInput().exists()).toBe(true);
    });

    it('does not render title', () => {
      expect(findDropdownTitle().exists()).toBe(false);
    });
  });
});
