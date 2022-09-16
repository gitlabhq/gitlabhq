import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import JobItem from '~/pipelines/components/graph/job_item.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  delayedJob,
  mockJob,
  mockJobWithoutDetails,
  mockJobWithUnauthorizedAction,
  triggerJob,
} from './mock_data';

describe('pipeline graph job item', () => {
  let wrapper;

  const findJobWithoutLink = () => wrapper.findByTestId('job-without-link');
  const findJobWithLink = () => wrapper.findByTestId('job-with-link');
  const findActionComponent = () => wrapper.findByTestId('ci-action-component');
  const findBadge = () => wrapper.findComponent(GlBadge);

  const createWrapper = (propsData) => {
    wrapper = extendedWrapper(
      mount(JobItem, {
        propsData,
      }),
    );
  };

  const triggerActiveClass = 'gl-shadow-x0-y0-b3-s1-blue-500';

  afterEach(() => {
    wrapper.destroy();
  });

  describe('name with link', () => {
    it('should render the job name and status with a link', async () => {
      createWrapper({ job: mockJob });

      await nextTick();
      const link = wrapper.find('a');

      expect(link.attributes('href')).toBe(mockJob.status.detailsPath);

      expect(link.attributes('title')).toBe(`${mockJob.name} - ${mockJob.status.label}`);

      expect(wrapper.find('.ci-status-icon-success').exists()).toBe(true);

      expect(wrapper.text()).toBe(mockJob.name);
    });
  });

  describe('name without link', () => {
    beforeEach(() => {
      createWrapper({
        job: mockJobWithoutDetails,
        cssClassJobName: 'css-class-job-name',
        jobHovered: 'test',
      });
    });

    it('should render status and name', () => {
      expect(wrapper.find('.ci-status-icon-success').exists()).toBe(true);
      expect(wrapper.find('a').exists()).toBe(false);

      expect(wrapper.text()).toBe(mockJobWithoutDetails.name);
    });

    it('should apply hover class and provided class name', () => {
      expect(findJobWithoutLink().classes()).toContain('css-class-job-name');
    });
  });

  describe('action icon', () => {
    it('should render the action icon', () => {
      createWrapper({ job: mockJob });

      const actionComponent = findActionComponent();

      expect(actionComponent.exists()).toBe(true);
      expect(actionComponent.props('actionIcon')).toBe('retry');
      expect(actionComponent.attributes('disabled')).not.toBe('disabled');
    });

    it('should render disabled action icon when user cannot run the action', () => {
      createWrapper({ job: mockJobWithUnauthorizedAction });

      const actionComponent = findActionComponent();

      expect(actionComponent.exists()).toBe(true);
      expect(actionComponent.props('actionIcon')).toBe('stop');
      expect(actionComponent.attributes('disabled')).toBe('disabled');
    });
  });

  describe('job style', () => {
    beforeEach(() => {
      createWrapper({
        job: mockJob,
        cssClassJobName: 'css-class-job-name',
      });
    });

    it('should render provided class name', () => {
      expect(wrapper.find('a').classes()).toContain('css-class-job-name');
    });

    it('does not show a badge on the job item', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('does not apply the trigger job class', () => {
      expect(findJobWithLink().classes()).not.toContain('gl-rounded-lg');
    });
  });

  describe('status label', () => {
    it('should not render status label when it is not provided', () => {
      createWrapper({
        job: {
          id: 4258,
          name: 'test',
          status: {
            icon: 'status_success',
          },
        },
      });

      expect(findJobWithoutLink().attributes('title')).toBe('test');
    });

    it('should not render status label when it is  provided', () => {
      createWrapper({
        job: {
          id: 4259,
          name: 'test',
          status: {
            icon: 'status_success',
            label: 'success',
            tooltip: 'success',
          },
        },
      });

      expect(findJobWithoutLink().attributes('title')).toBe('test - success');
    });
  });

  describe('for delayed job', () => {
    it('displays remaining time in tooltip', () => {
      createWrapper({
        job: delayedJob,
      });

      expect(findJobWithLink().attributes('title')).toBe(
        `delayed job - delayed manual action (${wrapper.vm.remainingTime})`,
      );
    });
  });

  describe('trigger job', () => {
    describe('card', () => {
      beforeEach(() => {
        createWrapper({ job: triggerJob });
      });

      it('shows a badge on the job item', () => {
        expect(findBadge().exists()).toBe(true);
        expect(findBadge().text()).toBe('Trigger job');
      });

      it('applies a rounded corner style instead of the usual pill shape', () => {
        expect(findJobWithoutLink().classes()).toContain('gl-rounded-lg');
      });
    });

    describe('highlighting', () => {
      it.each`
        job                      | jobName                       | expanded | link
        ${mockJob}               | ${mockJob.name}               | ${true}  | ${true}
        ${mockJobWithoutDetails} | ${mockJobWithoutDetails.name} | ${true}  | ${false}
      `(
        `trigger job should stay highlighted when downstream is expanded`,
        ({ job, jobName, expanded, link }) => {
          createWrapper({ job, pipelineExpanded: { jobName, expanded } });
          const findJobEl = link ? findJobWithLink : findJobWithoutLink;

          expect(findJobEl().classes()).toContain(triggerActiveClass);
        },
      );

      it.each`
        job                      | jobName                       | expanded | link
        ${mockJob}               | ${mockJob.name}               | ${false} | ${true}
        ${mockJobWithoutDetails} | ${mockJobWithoutDetails.name} | ${false} | ${false}
      `(
        `trigger job should not be highlighted when downstream is not expanded`,
        ({ job, jobName, expanded, link }) => {
          createWrapper({ job, pipelineExpanded: { jobName, expanded } });
          const findJobEl = link ? findJobWithLink : findJobWithoutLink;

          expect(findJobEl().classes()).not.toContain(triggerActiveClass);
        },
      );
    });
  });

  describe('job classes', () => {
    it('job class is shown', () => {
      createWrapper({
        job: mockJob,
        cssClassJobName: 'my-class',
      });

      expect(wrapper.find('a').classes()).toContain('my-class');

      expect(wrapper.find('a').classes()).not.toContain(triggerActiveClass);
    });

    it('job class is shown, along with hover', () => {
      createWrapper({
        job: mockJob,
        cssClassJobName: 'my-class',
        sourceJobHovered: mockJob.name,
      });

      expect(wrapper.find('a').classes()).toContain('my-class');
      expect(wrapper.find('a').classes()).toContain(triggerActiveClass);
    });

    it('multiple job classes are shown', () => {
      createWrapper({
        job: mockJob,
        cssClassJobName: ['my-class-1', 'my-class-2'],
      });

      expect(wrapper.find('a').classes()).toContain('my-class-1');
      expect(wrapper.find('a').classes()).toContain('my-class-2');

      expect(wrapper.find('a').classes()).not.toContain(triggerActiveClass);
    });

    it('multiple job classes are shown conditionally', () => {
      createWrapper({
        job: mockJob,
        cssClassJobName: { 'my-class-1': true, 'my-class-2': true },
      });

      expect(wrapper.find('a').classes()).toContain('my-class-1');
      expect(wrapper.find('a').classes()).toContain('my-class-2');

      expect(wrapper.find('a').classes()).not.toContain(triggerActiveClass);
    });

    it('multiple job classes are shown, along with a hover', () => {
      createWrapper({
        job: mockJob,
        cssClassJobName: ['my-class-1', 'my-class-2'],
        sourceJobHovered: mockJob.name,
      });

      expect(wrapper.find('a').classes()).toContain('my-class-1');
      expect(wrapper.find('a').classes()).toContain('my-class-2');
      expect(wrapper.find('a').classes()).toContain(triggerActiveClass);
    });
  });
});
