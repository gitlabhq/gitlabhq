import Vue, { nextTick } from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import radioGroup from '~/ide/components/commit_sidebar/radio_group.vue';
import { createStore } from '~/ide/stores';

describe('IDE commit sidebar radio group', () => {
  let vm;
  let store;

  beforeEach(async () => {
    store = createStore();

    const Component = Vue.extend(radioGroup);

    store.state.commit.commitAction = '2';

    vm = createComponentWithStore(Component, store, {
      value: '1',
      label: 'test',
      checked: true,
    });

    vm.$mount();

    await nextTick();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('uses label if present', () => {
    expect(vm.$el.textContent).toContain('test');
  });

  it('uses slot if label is not present', async () => {
    vm.$destroy();

    vm = new Vue({
      components: {
        radioGroup,
      },
      store,
      render: (createElement) =>
        createElement('radio-group', { props: { value: '1' } }, 'Testing slot'),
    });

    vm.$mount();

    await nextTick();
    expect(vm.$el.textContent).toContain('Testing slot');
  });

  it('updates store when changing radio button', async () => {
    vm.$el.querySelector('input').dispatchEvent(new Event('change'));

    await nextTick();
    expect(store.state.commit.commitAction).toBe('1');
  });

  describe('with input', () => {
    beforeEach(async () => {
      vm.$destroy();

      const Component = Vue.extend(radioGroup);

      store.state.commit.commitAction = '1';
      store.state.commit.newBranchName = 'test-123';

      vm = createComponentWithStore(Component, store, {
        value: '1',
        label: 'test',
        checked: true,
        showInput: true,
      });

      vm.$mount();

      await nextTick();
    });

    it('renders input box when commitAction matches value', () => {
      expect(vm.$el.querySelector('.form-control')).not.toBeNull();
    });

    it('hides input when commitAction doesnt match value', async () => {
      store.state.commit.commitAction = '2';

      await nextTick();
      expect(vm.$el.querySelector('.form-control')).toBeNull();
    });

    it('updates branch name in store on input', async () => {
      const input = vm.$el.querySelector('.form-control');
      input.value = 'testing-123';
      input.dispatchEvent(new Event('input'));

      await nextTick();
      expect(store.state.commit.newBranchName).toBe('testing-123');
    });

    it('renders newBranchName if present', () => {
      const input = vm.$el.querySelector('.form-control');

      expect(input.value).toBe('test-123');
    });
  });

  describe('tooltipTitle', () => {
    it('returns title when disabled', () => {
      vm.title = 'test title';
      vm.disabled = true;

      expect(vm.tooltipTitle).toBe('test title');
    });

    it('returns blank when not disabled', () => {
      vm.title = 'test title';

      expect(vm.tooltipTitle).not.toBe('test title');
    });
  });
});
