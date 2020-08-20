import Vue from 'vue';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import DraftsCount from '~/batch_comments/components/drafts_count.vue';
import { createStore } from '~/batch_comments/stores';

describe('Batch comments drafts count component', () => {
  let vm;
  let Component;

  beforeAll(() => {
    Component = Vue.extend(DraftsCount);
  });

  beforeEach(() => {
    const store = createStore();

    store.state.batchComments.drafts.push('comment');

    vm = mountComponentWithStore(Component, { store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders count', () => {
    expect(vm.$el.textContent).toContain('1');
  });

  it('renders screen reader text', done => {
    const el = vm.$el.querySelector('.sr-only');

    expect(el.textContent).toContain('draft');

    vm.$store.state.batchComments.drafts.push('comment 2');

    vm.$nextTick(() => {
      expect(el.textContent).toContain('drafts');

      done();
    });
  });
});
