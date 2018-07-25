import Vue from 'vue';

import SectionRevealButtonComponent from 'ee/geo_nodes/components/node_detail_sections/section_reveal_button.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = (buttonTitle = 'Foo button') => {
  const Component = Vue.extend(SectionRevealButtonComponent);

  return mountComponent(Component, {
    buttonTitle,
  });
};

describe('SectionRevealButton', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.toggleState).toBe(false);
    });
  });

  describe('computed', () => {
    it('return `angle-up` when toggleState prop is true', () => {
      vm.toggleState = true;
      expect(vm.toggleButtonIcon).toBe('angle-up');
    });

    it('return `angle-down` when toggleState prop is false', () => {
      vm.toggleState = false;
      expect(vm.toggleButtonIcon).toBe('angle-down');
    });
  });

  describe('methods', () => {
    describe('onClickButton', () => {
      it('updates `toggleState` prop to toggle from previous value', () => {
        vm.toggleState = true;
        vm.onClickButton();
        expect(vm.toggleState).toBe(false);
      });

      it('emits `toggleButton` event on component', () => {
        spyOn(vm, '$emit');
        vm.onClickButton();
        expect(vm.$emit).toHaveBeenCalledWith('toggleButton', vm.toggleState);
      });
    });
  });

  describe('template', () => {
    it('renders button element', () => {
      expect(vm.$el.classList.contains('btn-show-section')).toBe(true);
      expect(vm.$el.querySelector('svg use').getAttribute('xlink:href')).toContain('#angle-down');
      expect(vm.$el.querySelector('span').innerText.trim()).toBe('Foo button');
    });
  });
});
