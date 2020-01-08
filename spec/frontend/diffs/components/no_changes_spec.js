import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { createStore } from '~/mr_notes/stores';
import NoChanges from '~/diffs/components/no_changes.vue';

describe('Diff no changes empty state', () => {
  let vm;

  function createComponent(extendStore = () => {}) {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const store = createStore();
    extendStore(store);

    vm = shallowMount(NoChanges, {
      localVue,
      store,
      propsData: {
        changesEmptyStateIllustration: '',
      },
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('prevents XSS', () => {
    createComponent(store => {
      // eslint-disable-next-line no-param-reassign
      store.state.notes.noteableData = {
        source_branch: '<script>alert("test");</script>',
        target_branch: '<script>alert("test");</script>',
      };
    });

    expect(vm.contains('script')).toBe(false);
  });
});
