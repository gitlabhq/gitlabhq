import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import delayedJobFixture from 'test_fixtures/jobs/delayed.json';
import JobContainerItem from '~/ci/job_details/components/sidebar/job_container_item.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import job from 'jest/ci/jobs_mock_data';

describe('JobContainerItem', () => {
  let wrapper;

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findGlIcon = () => wrapper.findComponent(GlIcon);

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

  describe('when a job is not active and not retried', () => {
    beforeEach(() => {
      createComponent(job);
    });

    it('displays a status icon', () => {
      expect(findCiIcon().props('status')).toBe(job.status);
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
      expect(findGlIcon().props('name')).toBe('arrow-right');
    });
  });

  describe('when a job is retried', () => {
    beforeEach(() => {
      createComponent(job, { isActive: false, retried: true });
    });

    it('displays a retry icon', () => {
      expect(findGlIcon().props('name')).toBe('retry');
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
      await nextTick();

      const link = wrapper.findComponent(GlLink);

      expect(link.attributes('title')).toMatch('delayed job - delayed manual action (00:22:17)');
    });
  });
});
