import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import DropdownContents from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_contents.vue';

import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

import { mockConfig } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (initialState = mockConfig, propsData = {}) => {
  const store = new Vuex.Store(labelsSelectModule());

  store.dispatch('setInitialState', initialState);

  return shallowMount(DropdownContents, {
    propsData,
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
      expect(wrapper.attributes('style')).toBe(undefined);
    });

    it('renders component container element with styles when `renderOnTop` is true', () => {
      wrapper = createComponent(mockConfig, { renderOnTop: true });

      expect(wrapper.attributes('style')).toContain('bottom: 100%');
    });
  });
});
