import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import LabelsSelectRoot from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import DropdownTitle from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_title.vue';
import DropdownValue from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_value.vue';
import DropdownValueCollapsed from '~/vue_shared/components/sidebar/labels_select/dropdown_value_collapsed.vue';
import DropdownButton from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_button.vue';
import DropdownContents from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_contents.vue';

import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

import { mockConfig } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (config = mockConfig, slots = {}) =>
  shallowMount(LabelsSelectRoot, {
    localVue,
    slots,
    store: new Vuex.Store(labelsSelectModule()),
    propsData: config,
  });

describe('LabelsSelectRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('handleVuexActionDispatch', () => {
      it('calls `handleDropdownClose` when params `action.type` is `toggleDropdownContents` and state has `showDropdownButton` & `showDropdownContents` props `false`', () => {
        jest.spyOn(wrapper.vm, 'handleDropdownClose').mockImplementation();

        wrapper.vm.handleVuexActionDispatch(
          { type: 'toggleDropdownContents' },
          {
            showDropdownButton: false,
            showDropdownContents: false,
            labels: [{ id: 1 }, { id: 2, touched: true }],
          },
        );

        expect(wrapper.vm.handleDropdownClose).toHaveBeenCalledWith(
          expect.arrayContaining([
            {
              id: 2,
              touched: true,
            },
          ]),
        );
      });
    });

    describe('handleDropdownClose', () => {
      it('emits `updateSelectedLabels` & `onDropdownClose` events on component when provided `labels` param is not empty', () => {
        wrapper.vm.handleDropdownClose([{ id: 1 }, { id: 2 }]);

        expect(wrapper.emitted().updateSelectedLabels).toBeTruthy();
        expect(wrapper.emitted().onDropdownClose).toBeTruthy();
      });

      it('emits only `onDropdownClose` event on component when provided `labels` param is empty', () => {
        wrapper.vm.handleDropdownClose([]);

        expect(wrapper.emitted().updateSelectedLabels).toBeFalsy();
        expect(wrapper.emitted().onDropdownClose).toBeTruthy();
      });
    });

    describe('handleCollapsedValueClick', () => {
      it('emits `toggleCollapse` event on component', () => {
        wrapper.vm.handleCollapsedValueClick();

        expect(wrapper.emitted().toggleCollapse).toBeTruthy();
      });
    });
  });

  describe('template', () => {
    it('renders component with classes `labels-select-wrapper position-relative`', () => {
      expect(wrapper.attributes('class')).toContain('labels-select-wrapper position-relative');
    });

    it('renders component root element with CSS class `is-standalone` when `state.variant` is "standalone"', () => {
      const wrapperStandalone = createComponent({
        ...mockConfig,
        variant: 'standalone',
      });

      return wrapperStandalone.vm.$nextTick(() => {
        expect(wrapperStandalone.classes()).toContain('is-standalone');

        wrapperStandalone.destroy();
      });
    });

    it('renders `dropdown-value-collapsed` component when `allowLabelCreate` prop is `true`', () => {
      expect(wrapper.find(DropdownValueCollapsed).exists()).toBe(true);
    });

    it('renders `dropdown-title` component', () => {
      expect(wrapper.find(DropdownTitle).exists()).toBe(true);
    });

    it('renders `dropdown-value` component with slot when `showDropdownButton` prop is `false`', () => {
      const wrapperDropdownValue = createComponent(mockConfig, {
        default: 'None',
      });
      wrapperDropdownValue.vm.$store.state.showDropdownButton = false;

      return wrapperDropdownValue.vm.$nextTick(() => {
        const valueComp = wrapperDropdownValue.find(DropdownValue);

        expect(valueComp.exists()).toBe(true);
        expect(valueComp.text()).toBe('None');

        wrapperDropdownValue.destroy();
      });
    });

    it('renders `dropdown-button` component when `showDropdownButton` prop is `true`', () => {
      wrapper.vm.$store.dispatch('toggleDropdownButton');

      expect(wrapper.find(DropdownButton).exists()).toBe(true);
    });

    it('renders `dropdown-contents` component when `showDropdownButton` & `showDropdownContents` prop is `true`', () => {
      wrapper.vm.$store.dispatch('toggleDropdownContents');

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(DropdownContents).exists()).toBe(true);
      });
    });
  });
});
