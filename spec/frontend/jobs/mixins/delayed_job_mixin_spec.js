import { shallowMount } from '@vue/test-utils';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';

describe('DelayedJobMixin', () => {
  let wrapper;
  const delayedJobFixture = getJSONFixture('jobs/delayed.json');
  const dummyComponent = {
    props: {
      job: {
        type: Object,
        required: true,
      },
    },
    mixins: [delayedJobMixin],
    template: '<div>{{remainingTime}}</div>',
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('if job is empty object', () => {
    beforeEach(() => {
      wrapper = shallowMount(dummyComponent, {
        propsData: {
          job: {},
        },
      });
    });

    it('sets remaining time to 00:00:00', () => {
      expect(wrapper.text()).toBe('00:00:00');
    });

    it('does not update remaining time after mounting', async () => {
      await wrapper.vm.$nextTick();

      expect(wrapper.text()).toBe('00:00:00');
    });
  });

  describe('in REST component', () => {
    describe('if job is delayed job', () => {
      let remainingTimeInMilliseconds = 42000;

      beforeEach(async () => {
        jest
          .spyOn(Date, 'now')
          .mockImplementation(
            () => new Date(delayedJobFixture.scheduled_at).getTime() - remainingTimeInMilliseconds,
          );

        wrapper = shallowMount(dummyComponent, {
          propsData: {
            job: delayedJobFixture,
          },
        });

        await wrapper.vm.$nextTick();
      });

      it('sets remaining time', () => {
        expect(wrapper.text()).toBe('00:00:42');
      });

      it('updates remaining time', async () => {
        remainingTimeInMilliseconds = 41000;
        jest.advanceTimersByTime(1000);

        await wrapper.vm.$nextTick();
        expect(wrapper.text()).toBe('00:00:41');
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

      beforeEach(async () => {
        jest
          .spyOn(Date, 'now')
          .mockImplementation(
            () => mockGraphQlJob.scheduledAt.getTime() - remainingTimeInMilliseconds,
          );

        wrapper = shallowMount(dummyComponent, {
          propsData: {
            job: mockGraphQlJob,
          },
        });

        await wrapper.vm.$nextTick();
      });

      it('sets remaining time', () => {
        expect(wrapper.text()).toBe('00:00:42');
      });

      it('updates remaining time', async () => {
        remainingTimeInMilliseconds = 41000;
        jest.advanceTimersByTime(1000);

        await wrapper.vm.$nextTick();
        expect(wrapper.text()).toBe('00:00:41');
      });
    });
  });
});
