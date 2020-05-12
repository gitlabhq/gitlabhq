import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';

describe('DelayedJobMixin', () => {
  const delayedJobFixture = getJSONFixture('jobs/delayed.json');
  const dummyComponent = Vue.extend({
    mixins: [delayedJobMixin],
    props: {
      job: {
        type: Object,
        required: true,
      },
    },
    render(createElement) {
      return createElement('div', this.remainingTime);
    },
  });

  let vm;

  afterEach(() => {
    vm.$destroy();
    jest.clearAllTimers();
  });

  describe('if job is empty object', () => {
    beforeEach(() => {
      vm = mountComponent(dummyComponent, {
        job: {},
      });
    });

    it('sets remaining time to 00:00:00', () => {
      expect(vm.$el.innerText).toBe('00:00:00');
    });

    describe('after mounting', () => {
      beforeEach(() => vm.$nextTick());

      it('does not update remaining time', () => {
        expect(vm.$el.innerText).toBe('00:00:00');
      });
    });
  });

  describe('if job is delayed job', () => {
    let remainingTimeInMilliseconds = 42000;

    beforeEach(() => {
      jest
        .spyOn(Date, 'now')
        .mockImplementation(
          () => new Date(delayedJobFixture.scheduled_at).getTime() - remainingTimeInMilliseconds,
        );

      vm = mountComponent(dummyComponent, {
        job: delayedJobFixture,
      });
    });

    describe('after mounting', () => {
      beforeEach(() => vm.$nextTick());

      it('sets remaining time', () => {
        expect(vm.$el.innerText).toBe('00:00:42');
      });

      it('updates remaining time', () => {
        remainingTimeInMilliseconds = 41000;
        jest.advanceTimersByTime(1000);

        return vm.$nextTick().then(() => {
          expect(vm.$el.innerText).toBe('00:00:41');
        });
      });
    });
  });
});
