import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import DropdownButton from '~/sidebar/components/labels/labels_select_vue/dropdown_button.vue';

import labelSelectModule from '~/sidebar/components/labels/labels_select_vue/store';

import { mockConfig } from './mock_data';

let store;
Vue.use(Vuex);

const createComponent = (initialState = mockConfig) => {
  store = new Vuex.Store(labelSelectModule());

  store.dispatch('setInitialState', initialState);

  return shallowMount(DropdownButton, {
    store,
  });
};

describe('DropdownButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  const findDropdownButton = () => wrapper.findComponent(GlButton);
  const findDropdownText = () => wrapper.find('.dropdown-toggle-text');
  const findDropdownIcon = () => wrapper.findComponent(GlIcon);

  describe('methods', () => {
    describe('handleButtonClick', () => {
      it.each`
        variant         | expectPropagationStopped
        ${'standalone'} | ${true}
        ${'embedded'}   | ${false}
      `(
        'toggles dropdown content and handles event propagation when `state.variant` is "$variant"',
        ({ variant, expectPropagationStopped }) => {
          const event = { stopPropagation: jest.fn() };

          wrapper = createComponent({ ...mockConfig, variant });

          findDropdownButton().vm.$emit('click', event);

          expect(store.state.showDropdownContents).toBe(true);
          expect(event.stopPropagation).toHaveBeenCalledTimes(expectPropagationStopped ? 1 : 0);
        },
      );
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(wrapper.findComponent(GlButton).element).toBe(wrapper.element);
    });

    it('renders default button text element', () => {
      const dropdownTextEl = findDropdownText();

      expect(dropdownTextEl.exists()).toBe(true);
      expect(dropdownTextEl.text()).toBe('Label');
    });

    it('renders provided button text element', async () => {
      store.state.dropdownButtonText = 'Custom label';
      const dropdownTextEl = findDropdownText();

      await nextTick();
      expect(dropdownTextEl.text()).toBe('Custom label');
    });

    it('renders chevron icon element', () => {
      const iconEl = findDropdownIcon();

      expect(iconEl.exists()).toBe(true);
      expect(iconEl.props('name')).toBe('chevron-down');
    });
  });
});
