import Vue from 'vue';
import ScrollButton from '~/ide/components/jobs/detail/scroll_button.vue';
import mountComponent from '../../../../helpers/vue_mount_component_helper';

describe('IDE job log scroll button', () => {
  const Component = Vue.extend(ScrollButton);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      direction: 'up',
      disabled: false,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('iconName', () => {
    ['up', 'down'].forEach(direction => {
      it(`returns icon name for ${direction}`, () => {
        vm.direction = direction;

        expect(vm.iconName).toBe(`scroll_${direction}`);
      });
    });
  });

  describe('tooltipTitle', () => {
    it('returns title for up', () => {
      expect(vm.tooltipTitle).toBe('Scroll to top');
    });

    it('returns title for down', () => {
      vm.direction = 'down';

      expect(vm.tooltipTitle).toBe('Scroll to bottom');
    });
  });

  it('emits click event on click', () => {
    jest.spyOn(vm, '$emit').mockImplementation(() => {});

    vm.$el.querySelector('.btn-scroll').click();

    expect(vm.$emit).toHaveBeenCalledWith('click');
  });

  it('disables button when disabled is true', done => {
    vm.disabled = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.btn-scroll').hasAttribute('disabled')).toBe(true);

      done();
    });
  });
});
