import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import DropdownContents from '~/sidebar/components/labels/labels_select_vue/dropdown_contents.vue';
import labelsSelectModule from '~/sidebar/components/labels/labels_select_vue/store';
import {
  VARIANT_EMBEDDED,
  VARIANT_SIDEBAR,
  VARIANT_STANDALONE,
} from '~/sidebar/components/labels/labels_select_widget/constants';

import { mockConfig } from './mock_data';

Vue.use(Vuex);

const createComponent = (initialState = mockConfig, propsData = {}) => {
  const store = new Vuex.Store(labelsSelectModule());

  store.dispatch('setInitialState', initialState);

  return shallowMount(DropdownContents, {
    propsData,
    store,
  });
};

describe('DropdownContent', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
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
        variant               | expected
        ${VARIANT_SIDEBAR}    | ${'bottom: 3rem'}
        ${VARIANT_STANDALONE} | ${'bottom: 2rem'}
        ${VARIANT_EMBEDDED}   | ${'bottom: 2rem'}
      `('renders upward for $variant variant', ({ variant, expected }) => {
        wrapper = createComponent({ ...mockConfig, variant }, { renderOnTop: true });

        expect(wrapper.attributes('style')).toContain(expected);
      });
    });
  });
});
