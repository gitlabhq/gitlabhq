import Vue from 'vue';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import PublishButton from '~/batch_comments/components/publish_button.vue';
import { createStore } from '~/batch_comments/stores';

describe('Batch comments publish button component', () => {
  let vm;
  let Component;

  beforeAll(() => {
    Component = Vue.extend(PublishButton);
  });

  beforeEach(() => {
    const store = createStore();

    vm = mountComponentWithStore(Component, { store, props: { shouldPublish: true } });

    jest.spyOn(vm.$store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('dispatches publishReview on click', () => {
    vm.$el.click();

    expect(vm.$store.dispatch).toHaveBeenCalledWith('batchComments/publishReview', undefined);
  });

  it('sets loading when isPublishing is true', (done) => {
    vm.$store.state.batchComments.isPublishing = true;

    vm.$nextTick(() => {
      expect(vm.$el.getAttribute('disabled')).toBe('disabled');

      done();
    });
  });
});
