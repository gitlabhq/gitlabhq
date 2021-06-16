import { shallowMount, createLocalVue } from '@vue/test-utils';
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

const localVue = createLocalVue();
localVue.use(Vuex);

describe('LabelsSelectRoot', () => {
  let wrapper;
  let store;

  const createComponent = (config = mockConfig, slots = {}) => {
    wrapper = shallowMount(LabelsSelectRoot, {
      localVue,
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
      it('calls `handleDropdownClose` when params `action.type` is `toggleDropdownContents` and state has `showDropdownButton` & `showDropdownContents` props `false`', () => {
        createComponent();
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

      it('calls `handleDropdownClose` with state.labels filterd using `set` prop when dropdown variant is `embedded`', () => {
        createComponent({
          ...mockConfig,
          variant: 'embedded',
        });

        jest.spyOn(wrapper.vm, 'handleDropdownClose').mockImplementation();

        wrapper.vm.handleVuexActionDispatch(
          { type: 'toggleDropdownContents' },
          {
            showDropdownButton: false,
            showDropdownContents: false,
            labels: [{ id: 1 }, { id: 2, set: true }],
          },
        );

        expect(wrapper.vm.handleDropdownClose).toHaveBeenCalledWith(
          expect.arrayContaining([
            {
              id: 2,
              set: true,
            },
          ]),
        );
      });
    });

    describe('handleDropdownClose', () => {
      beforeEach(() => {
        createComponent();
      });

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
      ({ variant, cssClass }) => {
        createComponent({
          ...mockConfig,
          variant,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.classes()).toContain(cssClass);
        });
      },
    );

    it('renders `dropdown-value-collapsed` component when `allowLabelCreate` prop is `true`', async () => {
      createComponent();
      await wrapper.vm.$nextTick;
      expect(wrapper.find(DropdownValueCollapsed).exists()).toBe(true);
    });

    it('renders `dropdown-title` component', async () => {
      createComponent();
      await wrapper.vm.$nextTick;
      expect(wrapper.find(DropdownTitle).exists()).toBe(true);
    });

    it('renders `dropdown-value` component', async () => {
      createComponent(mockConfig, {
        default: 'None',
      });
      await wrapper.vm.$nextTick;

      const valueComp = wrapper.find(DropdownValue);

      expect(valueComp.exists()).toBe(true);
      expect(valueComp.text()).toBe('None');
    });

    it('renders `dropdown-button` component when `showDropdownButton` prop is `true`', async () => {
      createComponent();
      wrapper.vm.$store.dispatch('toggleDropdownButton');
      await wrapper.vm.$nextTick;
      expect(wrapper.find(DropdownButton).exists()).toBe(true);
    });

    it('renders `dropdown-contents` component when `showDropdownButton` & `showDropdownContents` prop is `true`', async () => {
      createComponent();
      wrapper.vm.$store.dispatch('toggleDropdownContents');
      await wrapper.vm.$nextTick;
      expect(wrapper.find(DropdownContents).exists()).toBe(true);
    });

    describe('sets content direction based on viewport', () => {
      describe.each(Object.values(DropdownVariant))(
        'when labels variant is "%s"',
        ({ variant }) => {
          beforeEach(() => {
            createComponent({ ...mockConfig, variant });
            wrapper.vm.$store.dispatch('toggleDropdownContents');
          });

          it('set direction when out of viewport', () => {
            isInViewport.mockImplementation(() => false);
            wrapper.vm.setContentIsOnViewport(wrapper.vm.$store.state);

            return wrapper.vm.$nextTick().then(() => {
              expect(wrapper.find(DropdownContents).props('renderOnTop')).toBe(true);
            });
          });

          it('does not set direction when inside of viewport', () => {
            isInViewport.mockImplementation(() => true);
            wrapper.vm.setContentIsOnViewport(wrapper.vm.$store.state);

            return wrapper.vm.$nextTick().then(() => {
              expect(wrapper.find(DropdownContents).props('renderOnTop')).toBe(false);
            });
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
});
