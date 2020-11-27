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

  describe('in REST component', () => {
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

  describe('in GraphQL component', () => {
    const mockGraphQlJob = {
      name: 'build_b',
      scheduledAt: new Date(delayedJobFixture.scheduled_at),
      status: {
        icon: 'status_success',
        tooltip: 'passed',
        hasDetails: true,
        detailsPath: '/root/abcd-dag/-/jobs/1515',
        group: 'success',
        action: null,
      },
    };

    describe('if job is delayed job', () => {
      let remainingTimeInMilliseconds = 42000;

      beforeEach(() => {
        jest
          .spyOn(Date, 'now')
          .mockImplementation(
            () => mockGraphQlJob.scheduledAt.getTime() - remainingTimeInMilliseconds,
          );

        vm = mountComponent(dummyComponent, {
          job: mockGraphQlJob,
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
});
