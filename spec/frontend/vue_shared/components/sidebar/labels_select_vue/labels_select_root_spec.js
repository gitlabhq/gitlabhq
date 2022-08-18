import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import { isInViewport } from '~/lib/utils/common_utils';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import DropdownButton from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_button.vue';
import DropdownContents from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_contents.vue';
import DropdownTitle from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_title.vue';
import DropdownValue from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_value.vue';
import DropdownValueCollapsed from '~/vue_shared/components/sidebar/labels_select_vue/dropdown_value_collapsed.vue';
import LabelsSelectRoot from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

import { mockConfig } from './mock_data';

jest.mock('~/lib/utils/common_utils', () => ({
  isInViewport: jest.fn().mockReturnValue(true),
}));

Vue.use(Vuex);

describe('LabelsSelectRoot', () => {
  let wrapper;
  let store;

  const createComponent = (config = mockConfig, slots = {}) => {
    wrapper = shallowMount(LabelsSelectRoot, {
      slots,
      store,
      propsData: config,
      stubs: {
        'dropdown-contents': DropdownContents,
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store(labelsSelectModule());
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('handleVuexActionDispatch', () => {
      const touchedLabels = [
        {
          id: 2,
          touched: true,
        },
      ];

      it('calls `handleDropdownClose` when params `action.type` is `toggleDropdownContents` and state has `showDropdownButton` & `showDropdownContents` props `false`', () => {
        createComponent();

        wrapper.vm.handleVuexActionDispatch(
          { type: 'toggleDropdownContents' },
          {
            showDropdownButton: false,
            showDropdownContents: false,
            labels: [{ id: 1 }, { id: 2, touched: true }],
          },
        );

        // We're utilizing `onDropdownClose` event emitted from the component to always include `touchedLabels`
        // while the first param of the method is the labels list which were added/removed.
        expect(wrapper.emitted('updateSelectedLabels')).toBeTruthy();
        expect(wrapper.emitted('updateSelectedLabels')[0]).toEqual([touchedLabels]);
        expect(wrapper.emitted('onDropdownClose')).toBeTruthy();
        expect(wrapper.emitted('onDropdownClose')[0]).toEqual([touchedLabels]);
      });

      it('calls `handleDropdownClose` with state.labels filterd using `set` prop when dropdown variant is `embedded`', () => {
        createComponent({
          ...mockConfig,
          variant: 'embedded',
        });

        wrapper.vm.handleVuexActionDispatch(
          { type: 'toggleDropdownContents' },
          {
            showDropdownButton: false,
            showDropdownContents: false,
            labels: [{ id: 1 }, { id: 2, set: true }],
          },
        );

        expect(wrapper.emitted('updateSelectedLabels')).toBeTruthy();
        expect(wrapper.emitted('updateSelectedLabels')[0]).toEqual([
          [
            {
              id: 2,
              set: true,
            },
          ],
        ]);
        expect(wrapper.emitted('onDropdownClose')).toBeTruthy();
        expect(wrapper.emitted('onDropdownClose')[0]).toEqual([[]]);
      });
    });

    describe('handleCollapsedValueClick', () => {
      it('emits `toggleCollapse` event on component', () => {
        createComponent();
        wrapper.vm.handleCollapsedValueClick();

        expect(wrapper.emitted().toggleCollapse).toBeTruthy();
      });
    });
  });

  describe('template', () => {
    it('renders component with classes `labels-select-wrapper position-relative`', () => {
      createComponent();
      expect(wrapper.attributes('class')).toContain('labels-select-wrapper position-relative');
    });

    it.each`
      variant         | cssClass
      ${'standalone'} | ${'is-standalone'}
      ${'embedded'}   | ${'is-embedded'}
    `(
      'renders component root element with CSS class `$cssClass` when `state.variant` is "$variant"',
      async ({ variant, cssClass }) => {
        createComponent({
          ...mockConfig,
          variant,
        });

        await nextTick();
        expect(wrapper.classes()).toContain(cssClass);
      },
    );

    it('renders `dropdown-value-collapsed` component when `allowLabelCreate` prop is `true`', async () => {
      createComponent();
      await nextTick();
      expect(wrapper.findComponent(DropdownValueCollapsed).exists()).toBe(true);
    });

    it('renders `dropdown-title` component', async () => {
      createComponent();
      await nextTick();
      expect(wrapper.findComponent(DropdownTitle).exists()).toBe(true);
    });

    it('renders `dropdown-value` component', async () => {
      createComponent(mockConfig, {
        default: 'None',
      });
      await nextTick();

      const valueComp = wrapper.findComponent(DropdownValue);

      expect(valueComp.exists()).toBe(true);
      expect(valueComp.text()).toBe('None');
    });

    it('renders `dropdown-button` component when `showDropdownButton` prop is `true`', async () => {
      createComponent();
      wrapper.vm.$store.dispatch('toggleDropdownButton');
      await nextTick();
      expect(wrapper.findComponent(DropdownButton).exists()).toBe(true);
    });

    it('renders `dropdown-contents` component when `showDropdownButton` & `showDropdownContents` prop is `true`', async () => {
      createComponent();
      wrapper.vm.$store.dispatch('toggleDropdownContents');
      await nextTick();
      expect(wrapper.findComponent(DropdownContents).exists()).toBe(true);
    });

    describe('sets content direction based on viewport', () => {
      describe.each(Object.values(DropdownVariant))(
        'when labels variant is "%s"',
        ({ variant }) => {
          beforeEach(() => {
            createComponent({ ...mockConfig, variant });
            wrapper.vm.$store.dispatch('toggleDropdownContents');
          });

          it('set direction when out of viewport', async () => {
            isInViewport.mockImplementation(() => false);
            wrapper.vm.setContentIsOnViewport(wrapper.vm.$store.state);

            await nextTick();
            expect(wrapper.findComponent(DropdownContents).props('renderOnTop')).toBe(true);
          });

          it('does not set direction when inside of viewport', async () => {
            isInViewport.mockImplementation(() => true);
            wrapper.vm.setContentIsOnViewport(wrapper.vm.$store.state);

            await nextTick();
            expect(wrapper.findComponent(DropdownContents).props('renderOnTop')).toBe(false);
          });
        },
      );
    });
  });

  it('calls toggleDropdownContents action when isEditing prop is changing to true', async () => {
    createComponent();

    jest.spyOn(store, 'dispatch').mockResolvedValue();
    await wrapper.setProps({ isEditing: true });

    expect(store.dispatch).toHaveBeenCalledWith('toggleDropdownContents');
  });

  it('does not call toggleDropdownContents action when isEditing prop is changing to false', async () => {
    createComponent();

    jest.spyOn(store, 'dispatch').mockResolvedValue();
    await wrapper.setProps({ isEditing: false });

    expect(store.dispatch).not.toHaveBeenCalled();
  });

  it('calls updateLabelsSetState after selected labels were updated', async () => {
    createComponent();

    jest.spyOn(store, 'dispatch').mockResolvedValue();
    await wrapper.setProps({ selectedLabels: [] });
    jest.advanceTimersByTime(100);

    expect(store.dispatch).toHaveBeenCalledWith('updateLabelsSetState');
  });
});
