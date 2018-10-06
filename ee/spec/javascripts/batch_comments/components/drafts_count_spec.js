import Vue from 'vue';
import DraftsCount from 'ee/batch_comments/components/drafts_count.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';

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
    expect(vm.$el.querySelector('.drafts-count-number').textContent).toBe('1');
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
