import Vue from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import dropdownSearchInputComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_search_input.vue';

const createComponent = () => {
  const Component = Vue.extend(dropdownSearchInputComponent);

  return mountComponent(Component);
};

describe('DropdownSearchInputComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders input element with type `search`', () => {
      const inputEl = vm.$el.querySelector('input.dropdown-input-field');

      expect(inputEl).not.toBeNull();
      expect(inputEl.getAttribute('type')).toBe('search');
    });

    it('renders search icon element', () => {
      expect(vm.$el.querySelector('.fa-search.dropdown-input-search')).not.toBeNull();
    });

    it('renders clear search icon element', () => {
      expect(
        vm.$el.querySelector('.fa-times.dropdown-input-clear.js-dropdown-input-clear'),
      ).not.toBeNull();
    });
  });
});
