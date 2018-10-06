import Vue from 'vue';
import PublishButton from 'ee/batch_comments/components/publish_button.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from 'ee/batch_comments/stores';

describe('Batch comments drafts count component', () => {
  let vm;
  let Component;

  beforeAll(() => {
    Component = Vue.extend(PublishButton);
  });

  beforeEach(() => {
    const store = createStore();

    vm = mountComponentWithStore(Component, { store });

    spyOn(vm.$store, 'dispatch').and.stub();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('dispatches publishReview on click', () => {
    vm.$el.click();

    expect(vm.$store.dispatch).toHaveBeenCalledWith(
      'batchComments/publishReview',
      jasmine.anything(),
    );
  });

  it('sets loading when isPublishing is true', done => {
    vm.$store.state.batchComments.isPublishing = true;

    vm.$nextTick(() => {
      expect(vm.$el.getAttribute('disabled')).toBe('disabled');

      done();
    });
  });
});
