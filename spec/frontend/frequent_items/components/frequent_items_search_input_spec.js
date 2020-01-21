import { shallowMount } from '@vue/test-utils';
import searchComponent from '~/frequent_items/components/frequent_items_search_input.vue';
import eventHub from '~/frequent_items/event_hub';

const createComponent = (namespace = 'projects') =>
  shallowMount(searchComponent, {
    propsData: { namespace },
  });

describe('FrequentItemsSearchInputComponent', () => {
  let wrapper;
  let vm;

  beforeEach(() => {
    wrapper = createComponent();

    ({ vm } = wrapper);
  });

  afterEach(() => {
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
    it('should listen `dropdownOpen` event', done => {
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
    it('should unbind event listeners on eventHub', done => {
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
      expect(wrapper.contains('input.form-control')).toBe(true);
      expect(wrapper.contains('.search-icon')).toBe(true);
      expect(wrapper.find('input.form-control').attributes('placeholder')).toBe(
        'Search your projects',
      );
    });
  });
});
