import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlIcon } from '@gitlab/ui';
import DropdownButton from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_button.vue';

import labelSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

import { mockConfig } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (initialState = mockConfig) => {
  const store = new Vuex.Store(labelSelectModule());

  store.dispatch('setInitialState', initialState);

  return shallowMount(DropdownButton, {
    localVue,
    store,
  });
};

describe('DropdownButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('handleButtonClick', () => {
      it('calls action `toggleDropdownContents` and stops event propagation when `state.variant` is "standalone"', () => {
        const event = {
          stopPropagation: jest.fn(),
        };
        wrapper = createComponent({
          ...mockConfig,
          variant: 'standalone',
        });

        jest.spyOn(wrapper.vm, 'toggleDropdownContents');

        wrapper.vm.handleButtonClick(event);

        expect(wrapper.vm.toggleDropdownContents).toHaveBeenCalled();
        expect(event.stopPropagation).toHaveBeenCalled();

        wrapper.destroy();
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(wrapper.is('gl-button-stub')).toBe(true);
    });

    it('renders button text element', () => {
      const dropdownTextEl = wrapper.find('.dropdown-toggle-text');

      expect(dropdownTextEl.exists()).toBe(true);
      expect(dropdownTextEl.text()).toBe('Label');
    });

    it('renders chevron icon element', () => {
      const iconEl = wrapper.find(GlIcon);

      expect(iconEl.exists()).toBe(true);
      expect(iconEl.props('name')).toBe('chevron-down');
    });
  });
});
