import Vue from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import itemTypeIconComponent from '~/groups/components/item_type_icon.vue';
import { ITEM_TYPE } from '../mock_data';

const createComponent = (itemType = ITEM_TYPE.GROUP, isGroupOpen = false) => {
  const Component = Vue.extend(itemTypeIconComponent);

  return mountComponent(Component, {
    itemType,
    isGroupOpen,
  });
};

describe('ItemTypeIconComponent', () => {
  describe('template', () => {
    it('should render component template correctly', () => {
      const vm = createComponent();

      expect(vm.$el.classList.contains('item-type-icon')).toBeTruthy();
      vm.$destroy();
    });

    it('should render folder open or close icon based `isGroupOpen` prop value', () => {
      let vm;

      vm = createComponent(ITEM_TYPE.GROUP, true);

      expect(vm.$el.querySelector('svg').getAttribute('data-testid')).toBe('folder-open-icon');
      vm.$destroy();

      vm = createComponent(ITEM_TYPE.GROUP);

      expect(vm.$el.querySelector('svg').getAttribute('data-testid')).toBe('folder-o-icon');
      vm.$destroy();
    });

    it('should render bookmark icon based on `isProject` prop value', () => {
      let vm;

      vm = createComponent(ITEM_TYPE.PROJECT);

      expect(vm.$el.querySelector('svg').getAttribute('data-testid')).toBe('bookmark-icon');
      vm.$destroy();

      vm = createComponent(ITEM_TYPE.GROUP);

      expect(vm.$el.querySelector('svg').getAttribute('data-testid')).not.toBe('bookmark-icon');
      vm.$destroy();
    });
  });
});
