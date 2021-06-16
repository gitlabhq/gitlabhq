import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';

import DropdownButton from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_button.vue';

import labelSelectModule from '~/vue_shared/components/sidebar/labels_select_widget/store';

import { mockConfig } from './mock_data';

let store;
const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (initialState = mockConfig) => {
  store = new Vuex.Store(labelSelectModule());

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

  const findDropdownButton = () => wrapper.find(GlButton);
  const findDropdownText = () => wrapper.find('.dropdown-toggle-text');
  const findDropdownIcon = () => wrapper.find(GlIcon);

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
      expect(wrapper.find(GlButton).element).toBe(wrapper.element);
    });

    it('renders default button text element', () => {
      const dropdownTextEl = findDropdownText();

      expect(dropdownTextEl.exists()).toBe(true);
      expect(dropdownTextEl.text()).toBe('Label');
    });

    it('renders provided button text element', () => {
      store.state.dropdownButtonText = 'Custom label';
      const dropdownTextEl = findDropdownText();

      return wrapper.vm.$nextTick().then(() => {
        expect(dropdownTextEl.text()).toBe('Custom label');
      });
    });

    it('renders chevron icon element', () => {
      const iconEl = findDropdownIcon();

      expect(iconEl.exists()).toBe(true);
      expect(iconEl.props('name')).toBe('chevron-down');
    });
  });
});
