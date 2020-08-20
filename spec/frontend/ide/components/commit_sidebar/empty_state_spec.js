import Vue from 'vue';
import { createStore } from '~/ide/stores';
import emptyState from '~/ide/components/commit_sidebar/empty_state.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';

describe('IDE commit panel empty state', () => {
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();

    const Component = Vue.extend(emptyState);

    Vue.set(store.state, 'noChangesStateSvgPath', 'no-changes');

    vm = createComponentWithStore(Component, store);

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders no changes text when last commit message is empty', () => {
    expect(vm.$el.textContent).toContain('No changes');
  });
});
