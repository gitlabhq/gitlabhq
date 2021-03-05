import { GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JobsContainer from '~/jobs/components/jobs_container.vue';

describe('Jobs List block', () => {
  let wrapper;

  const retried = {
    status: {
      details_path: '/gitlab-org/gitlab-foss/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
    id: 233432756,
    tooltip: 'build - passed',
    retried: true,
  };

  const active = {
    name: 'test',
    status: {
      details_path: '/gitlab-org/gitlab-foss/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
    id: 2322756,
    tooltip: 'build - passed',
    active: true,
  };

  const job = {
    name: 'build',
    status: {
      details_path: '/gitlab-org/gitlab-foss/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
    id: 232153,
    tooltip: 'build - passed',
  };

  const findAllJobs = () => wrapper.findAllComponents(GlLink);
  const findJob = () => findAllJobs().at(0);

  const findArrowIcon = () => wrapper.findByTestId('arrow-right-icon');
  const findRetryIcon = () => wrapper.findByTestId('retry-icon');

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      mount(JobsContainer, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a list of jobs', () => {
    createComponent({
      jobs: [job, retried, active],
      jobId: 12313,
    });

    expect(findAllJobs()).toHaveLength(3);
  });

  it('renders the arrow right icon when job id matches `jobId`', () => {
    createComponent({
      jobs: [active],
      jobId: active.id,
    });

    expect(findArrowIcon().exists()).toBe(true);
  });

  it('does not render the arrow right icon when the job is not active', () => {
    createComponent({
      jobs: [job],
      jobId: active.id,
    });

    expect(findArrowIcon().exists()).toBe(false);
  });

  it('renders the job name when present', () => {
    createComponent({
      jobs: [job],
      jobId: active.id,
    });

    expect(findJob().text()).toBe(job.name);
    expect(findJob().text()).not.toContain(job.id);
  });

  it('renders job id when job name is not available', () => {
    createComponent({
      jobs: [retried],
      jobId: active.id,
    });

    expect(findJob().text()).toBe(retried.id.toString());
  });

  it('links to the job page', () => {
    createComponent({
      jobs: [job],
      jobId: active.id,
    });

    expect(findJob().attributes('href')).toBe(job.status.details_path);
  });

  it('renders retry icon when job was retried', () => {
    createComponent({
      jobs: [retried],
      jobId: active.id,
    });

    expect(findRetryIcon().exists()).toBe(true);
  });

  it('does not render retry icon when job was not retried', () => {
    createComponent({
      jobs: [job],
      jobId: active.id,
    });

    expect(findRetryIcon().exists()).toBe(false);
  });
});
