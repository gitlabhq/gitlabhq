import Vue from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import itemCaretComponent from '~/groups/components/item_caret.vue';

const createComponent = (isGroupOpen = false) => {
  const Component = Vue.extend(itemCaretComponent);

  return mountComponent(Component, {
    isGroupOpen,
  });
};

describe('ItemCaretComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('should render component template correctly', () => {
      vm = createComponent();
      expect(vm.$el.classList.contains('folder-caret')).toBeTruthy();
      expect(vm.$el.querySelectorAll('svg').length).toBe(1);
    });

    it('should render caret down icon if `isGroupOpen` prop is `true`', () => {
      vm = createComponent(true);
      expect(vm.$el.querySelector('svg use').getAttribute('xlink:href')).toContain('angle-down');
    });

    it('should render caret right icon if `isGroupOpen` prop is `false`', () => {
      vm = createComponent();
      expect(vm.$el.querySelector('svg use').getAttribute('xlink:href')).toContain('angle-right');
    });
  });
});
