import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import toggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';

describe('toggleSidebar', () => {
  let vm;
  beforeEach(() => {
    const ToggleSidebar = Vue.extend(toggleSidebar);
    vm = mountComponent(ToggleSidebar, {
      collapsed: true,
    });
  });

  it('should render the "chevron-double-lg-left" icon when collapsed', () => {
    expect(vm.$el.querySelector('[data-testid="chevron-double-lg-left-icon"]')).not.toBeNull();
  });

  it('should render the "chevron-double-lg-right" icon when expanded', async () => {
    vm.collapsed = false;
    await Vue.nextTick();
    expect(vm.$el.querySelector('[data-testid="chevron-double-lg-right-icon"]')).not.toBeNull();
  });

  it('should emit toggle event when button clicked', () => {
    const toggle = jest.fn();
    vm.$on('toggle', toggle);
    vm.$el.click();

    expect(toggle).toHaveBeenCalled();
  });
});
