import Vue, { nextTick } from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import Button from '~/ide/components/new_dropdown/button.vue';

describe('IDE new entry dropdown button component', () => {
  let Component;
  let vm;

  beforeAll(() => {
    Component = Vue.extend(Button);
  });

  beforeEach(() => {
    vm = mountComponent(Component, {
      label: 'Testing',
      icon: 'doc-new',
    });

    jest.spyOn(vm, '$emit').mockImplementation(() => {});
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders button with label', () => {
    expect(vm.$el.textContent).toContain('Testing');
  });

  it('renders icon', () => {
    expect(vm.$el.querySelector('[data-testid="doc-new-icon"]')).not.toBe(null);
  });

  it('emits click event', () => {
    vm.$el.click();

    expect(vm.$emit).toHaveBeenCalledWith('click');
  });

  it('hides label if showLabel is false', async () => {
    vm.showLabel = false;

    await nextTick();
    expect(vm.$el.textContent).not.toContain('Testing');
  });

  describe('tooltipTitle', () => {
    it('returns empty string when showLabel is true', () => {
      expect(vm.tooltipTitle).toBe('');
    });

    it('returns label', async () => {
      vm.showLabel = false;

      await nextTick();
      expect(vm.tooltipTitle).toBe('Testing');
    });
  });
});
