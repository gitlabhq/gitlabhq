import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import JobItem from '~/pipelines/components/graph/job_item.vue';

describe('pipeline graph job item', () => {
  let wrapper;

  const findJobWithoutLink = () => wrapper.find('[data-testid="job-without-link"]');
  const findJobWithLink = () => wrapper.find('[data-testid="job-with-link"]');
  const findActionComponent = () => wrapper.find('[data-testid="ci-action-component"]');

  const createWrapper = (propsData) => {
    wrapper = mount(JobItem, {
      propsData,
    });
  };

  const triggerActiveClass = 'gl-shadow-x0-y0-b3-s1-blue-500';

  const delayedJob = {
    __typename: 'CiJob',
    name: 'delayed job',
    scheduledAt: '2015-07-03T10:01:00.000Z',
    needs: [],
    status: {
      __typename: 'DetailedStatus',
      icon: 'status_scheduled',
      tooltip: 'delayed manual action (%{remainingTime})',
      hasDetails: true,
      detailsPath: '/root/kinder-pipe/-/jobs/5339',
      group: 'scheduled',
      action: {
        __typename: 'StatusAction',
        icon: 'time-out',
        title: 'Unschedule',
        path: '/frontend-fixtures/builds-project/-/jobs/142/unschedule',
        buttonTitle: 'Unschedule job',
      },
    },
  };

  const mockJob = {
    id: 4256,
    name: 'test',
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      tooltip: 'passed',
      group: 'success',
      detailsPath: '/root/ci-mock/builds/4256',
      hasDetails: true,
      action: {
        icon: 'retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4256/retry',
        method: 'post',
      },
    },
  };
  const mockJobWithoutDetails = {
    id: 4257,
    name: 'job_without_details',
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      detailsPath: '/root/ci-mock/builds/4257',
      hasDetails: false,
    },
  };
  const mockJobWithUnauthorizedAction = {
    id: 4258,
    name: 'stop-environment',
    status: {
      icon: 'status_manual',
      label: 'manual stop action (not allowed)',
      tooltip: 'manual action',
      group: 'manual',
      detailsPath: '/root/ci-mock/builds/4258',
      hasDetails: true,
      action: null,
    },
  };

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

    it('it should render status and name', () => {
      expect(wrapper.find('.ci-status-icon-success').exists()).toBe(true);
      expect(wrapper.find('a').exists()).toBe(false);

      expect(wrapper.text()).toBe(mockJobWithoutDetails.name);
    });

    it('should apply hover class and provided class name', () => {
      expect(findJobWithoutLink().classes()).toContain('css-class-job-name');
    });
  });

  describe('action icon', () => {
    it('it should render the action icon', () => {
      createWrapper({ job: mockJob });

      const actionComponent = findActionComponent();

      expect(actionComponent.exists()).toBe(true);
      expect(actionComponent.props('actionIcon')).toBe('retry');
      expect(actionComponent.attributes('disabled')).not.toBe('disabled');
    });

    it('it should render disabled action icon when user cannot run the action', () => {
      createWrapper({ job: mockJobWithUnauthorizedAction });

      const actionComponent = findActionComponent();

      expect(actionComponent.exists()).toBe(true);
      expect(actionComponent.props('actionIcon')).toBe('stop');
      expect(actionComponent.attributes('disabled')).toBe('disabled');
    });
  });

  it('should render provided class name', () => {
    createWrapper({
      job: mockJob,
      cssClassJobName: 'css-class-job-name',
    });

    expect(wrapper.find('a').classes()).toContain('css-class-job-name');
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

  describe('trigger job highlighting', () => {
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
