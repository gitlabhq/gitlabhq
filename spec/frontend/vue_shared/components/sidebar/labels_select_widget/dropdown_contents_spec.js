import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';

import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import DropdownContents from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents.vue';
import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_widget/store';

import { mockConfig } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (initialState = mockConfig, defaultProps = {}) => {
  const store = new Vuex.Store(labelsSelectModule());

  store.dispatch('setInitialState', initialState);

  return shallowMount(DropdownContents, {
    propsData: {
      ...defaultProps,
      labelsCreateTitle: 'test',
    },
    localVue,
    store,
  });
};

describe('DropdownContent', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('dropdownContentsView', () => {
      it('returns string "dropdown-contents-create-view" when `showDropdownContentsCreateView` prop is `true`', () => {
        wrapper.vm.$store.dispatch('toggleDropdownContentsCreateView');

        expect(wrapper.vm.dropdownContentsView).toBe('dropdown-contents-create-view');
      });

      it('returns string "dropdown-contents-labels-view" when `showDropdownContentsCreateView` prop is `false`', () => {
        expect(wrapper.vm.dropdownContentsView).toBe('dropdown-contents-labels-view');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `labels-select-dropdown-contents` and no styles', () => {
      expect(wrapper.attributes('class')).toContain('labels-select-dropdown-contents');
      expect(wrapper.attributes('style')).toBeUndefined();
    });

    describe('when `renderOnTop` is true', () => {
      it.each`
        variant                       | expected
        ${DropdownVariant.Sidebar}    | ${'bottom: 3rem'}
        ${DropdownVariant.Standalone} | ${'bottom: 2rem'}
        ${DropdownVariant.Embedded}   | ${'bottom: 2rem'}
      `('renders upward for $variant variant', ({ variant, expected }) => {
        wrapper = createComponent({ ...mockConfig, variant }, { renderOnTop: true });

        expect(wrapper.attributes('style')).toContain(expected);
      });
    });
  });
});
