import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JobContainerItem from '~/jobs/components/job_container_item.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import job from '../mock_data';

describe('JobContainerItem', () => {
  let wrapper;
  const delayedJobFixture = getJSONFixture('jobs/delayed.json');

  const findCiIconComponent = () => wrapper.findComponent(CiIcon);
  const findGlIconComponent = () => wrapper.findComponent(GlIcon);

  function createComponent(jobData = {}, props = { isActive: false, retried: false }) {
    wrapper = shallowMount(JobContainerItem, {
      propsData: {
        job: {
          ...jobData,
          retried: props.retried,
        },
        isActive: props.isActive,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when a job is not active and not retried', () => {
    beforeEach(() => {
      createComponent(job);
    });

    it('displays a status icon', () => {
      const ciIcon = findCiIconComponent();

      expect(ciIcon.props('status')).toBe(job.status);
    });

    it('displays the job name', () => {
      expect(wrapper.text()).toContain(job.name);
    });

    it('displays a link to the job', () => {
      const link = wrapper.findComponent(GlLink);

      expect(link.attributes('href')).toBe(job.status.details_path);
    });
  });

  describe('when a job is active', () => {
    beforeEach(() => {
      createComponent(job, { isActive: true });
    });

    it('displays an arrow sprite icon', () => {
      const icon = findGlIconComponent();

      expect(icon.props('name')).toBe('arrow-right');
    });
  });

  describe('when a job is retried', () => {
    beforeEach(() => {
      createComponent(job, { isActive: false, retried: true });
    });

    it('displays a retry icon', () => {
      const icon = findGlIconComponent();

      expect(icon.props('name')).toBe('retry');
    });
  });

  describe('for a delayed job', () => {
    beforeEach(() => {
      const remainingMilliseconds = 1337000;
      jest
        .spyOn(Date, 'now')
        .mockImplementation(
          () => new Date(delayedJobFixture.scheduled_at).getTime() - remainingMilliseconds,
        );

      createComponent(delayedJobFixture);
    });

    it('displays remaining time in tooltip', async () => {
      await wrapper.vm.$nextTick();

      const link = wrapper.findComponent(GlLink);

      expect(link.attributes('title')).toMatch('delayed job - delayed manual action (00:22:17)');
    });
  });
});
