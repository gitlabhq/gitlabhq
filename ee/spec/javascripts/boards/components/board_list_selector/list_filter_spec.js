import Vue from 'vue';

import ListFilterComponent from 'ee/boards/components/boards_list_selector/list_filter.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = () => {
  const Component = Vue.extend(ListFilterComponent);

  return mountComponent(Component);
};

describe('ListFilterComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('handleInputChange', () => {
      it('emits `onSearchInput` event on component and sends `query` as event param', () => {
        spyOn(vm, '$emit');
        const query = 'foobar';
        vm.query = query;

        vm.handleInputChange();
        expect(vm.$emit).toHaveBeenCalledWith('onSearchInput', query);
      });
    });

    describe('handleInputClear', () => {
      it('clears value of prop `query` and calls `handleInputChange` method on component', () => {
        spyOn(vm, 'handleInputChange');
        vm.query = 'foobar';

        vm.handleInputClear();
        expect(vm.query).toBe('');
        expect(vm.handleInputChange).toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `dropdown-input`', () => {
      expect(vm.$el.classList.contains('dropdown-input')).toBe(true);
    });

    it('renders class `has-value` on container element when prop `query` is not empty', (done) => {
      vm.query = 'foobar';
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.classList.contains('has-value')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('removes class `has-value` from container element when prop `query` is empty', (done) => {
      vm.query = '';
      Vue.nextTick()
      .then(() => {
        expect(vm.$el.classList.contains('has-value')).toBe(false);
      })
      .then(done)
      .catch(done.fail);
    });

    it('renders search input element', () => {
      const inputEl = vm.$el.querySelector('input.dropdown-input-field');
      expect(inputEl).not.toBeNull();
      expect(inputEl.getAttribute('placeholder')).toBe('Search');
    });

    it('renders search input icons', () => {
      expect(vm.$el.querySelector('i.fa.fa-search.dropdown-input-search')).not.toBeNull();
      expect(vm.$el.querySelector('i.fa.fa-times.dropdown-input-clear')).not.toBeNull();
    });
  });
});
