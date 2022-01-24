import Vue, { nextTick } from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import successMessage from '~/ide/components/commit_sidebar/success_message.vue';
import { createStore } from '~/ide/stores';

describe('IDE commit panel successful commit state', () => {
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();

    const Component = Vue.extend(successMessage);

    vm = createComponentWithStore(Component, store, {
      committedStateSvgPath: 'committed-state',
    });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders last commit message when it exists', async () => {
    vm.$store.state.lastCommitMsg = 'testing commit message';

    await nextTick();
    expect(vm.$el.textContent).toContain('testing commit message');
  });
});
