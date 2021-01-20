import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import searchComponent from '~/frequent_items/components/frequent_items_search_input.vue';
import { createStore } from '~/frequent_items/store';
import eventHub from '~/frequent_items/event_hub';

describe('FrequentItemsSearchInputComponent', () => {
  let wrapper;
  let trackingSpy;
  let vm;
  let store;

  const createComponent = (namespace = 'projects') =>
    shallowMount(searchComponent, {
      store,
      propsData: { namespace },
    });

  beforeEach(() => {
    store = createStore({ dropdownType: 'project' });
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});

    trackingSpy = mockTracking('_category_', document, jest.spyOn);
    trackingSpy.mockImplementation(() => {});

    wrapper = createComponent();

    ({ vm } = wrapper);
  });

  afterEach(() => {
    unmockTracking();
    vm.$destroy();
  });

  describe('methods', () => {
    describe('setFocus', () => {
      it('should set focus to search input', () => {
        jest.spyOn(vm.$refs.search, 'focus').mockImplementation(() => {});

        vm.setFocus();

        expect(vm.$refs.search.focus).toHaveBeenCalled();
      });
    });
  });

  describe('mounted', () => {
    it('should listen `dropdownOpen` event', (done) => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});
      const vmX = createComponent().vm;

      vmX.$nextTick(() => {
        expect(eventHub.$on).toHaveBeenCalledWith(
          `${vmX.namespace}-dropdownOpen`,
          expect.any(Function),
        );
        done();
      });
    });
  });

  describe('beforeDestroy', () => {
    it('should unbind event listeners on eventHub', (done) => {
      const vmX = createComponent().vm;
      jest.spyOn(eventHub, '$off').mockImplementation(() => {});

      vmX.$mount();
      vmX.$destroy();

      vmX.$nextTick(() => {
        expect(eventHub.$off).toHaveBeenCalledWith(
          `${vmX.namespace}-dropdownOpen`,
          expect.any(Function),
        );
        done();
      });
    });
  });

  describe('template', () => {
    it('should render component element', () => {
      expect(wrapper.classes()).toContain('search-input-container');
      expect(wrapper.find('input.form-control').exists()).toBe(true);
      expect(wrapper.find('.search-icon').exists()).toBe(true);
      expect(wrapper.find('input.form-control').attributes('placeholder')).toBe(
        'Search your projects',
      );
    });
  });

  describe('tracking', () => {
    it('tracks when search query is entered', async () => {
      expect(trackingSpy).not.toHaveBeenCalled();
      expect(store.dispatch).not.toHaveBeenCalled();

      const value = 'my project';

      const input = wrapper.find('input');
      input.setValue(value);
      input.trigger('input');

      await wrapper.vm.$nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'type_search_query', {
        label: 'project_dropdown_frequent_items_search_input',
      });
      expect(store.dispatch).toHaveBeenCalledWith('setSearchQuery', value);
    });
  });
});
