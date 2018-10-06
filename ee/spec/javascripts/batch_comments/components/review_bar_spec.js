import Vue from 'vue';
import ReviewBar from 'ee/batch_comments/components/review_bar.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from 'ee/batch_comments/stores';

describe('Batch comments review bar component', () => {
  let vm;
  let Component;

  beforeAll(() => {
    Component = Vue.extend(ReviewBar);
  });

  beforeEach(() => {
    const store = createStore();

    vm = mountComponentWithStore(Component, { store });

    spyOn(vm.$store, 'dispatch').and.stub();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('hides when no drafts exist', () => {
    expect(vm.$el.style.display).toBe('none');
  });

  describe('with batch comments', () => {
    beforeEach(done => {
      vm.$store.state.batchComments.drafts.push('comment');

      vm.$nextTick(done);
    });

    it('shows bar', () => {
      expect(vm.$el.style.display).not.toBe('none');
    });

    it('calls discardReview when clicking modal button', done => {
      vm.$el.querySelector('.btn.btn-align-content').click();

      vm.$nextTick(() => {
        vm.$el.querySelector('.modal .btn-danger').click();

        expect(vm.$store.dispatch).toHaveBeenCalled();

        done();
      });
    });

    it('sets discard button as loading when isDiscarding is true', done => {
      vm.$store.state.batchComments.isDiscarding = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.btn-align-content').getAttribute('disabled')).toBe(
          'disabled',
        );
        done();
      });
    });
  });
});
