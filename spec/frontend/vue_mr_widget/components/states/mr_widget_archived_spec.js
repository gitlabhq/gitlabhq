import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import archivedComponent from '~/vue_merge_request_widget/components/states/mr_widget_archived.vue';

describe('MRWidgetArchived', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(archivedComponent);
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a ci status failed icon', () => {
    expect(vm.$el.querySelector('.ci-status-icon')).not.toBeNull();
  });

  it('renders information', () => {
    expect(vm.$el.querySelector('.bold').textContent.trim()).toEqual(
      'Merge unavailable: merge requests are read-only on archived projects.',
    );
  });
});
