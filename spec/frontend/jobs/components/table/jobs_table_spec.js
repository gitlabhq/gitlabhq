import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';
import { mockJobsInTable } from '../../mock_data';

describe('Jobs Table', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findStatusBadge = () => wrapper.findComponent(CiBadge);
  const findTableRows = () => wrapper.findAllByTestId('jobs-table-row');
  const findJobStage = () => wrapper.findByTestId('job-stage-name');
  const findJobName = () => wrapper.findByTestId('job-name');
  const findAllCoverageJobs = () => wrapper.findAllByTestId('job-coverage');

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(JobsTable, {
        propsData: {
          jobs: mockJobsInTable,
          ...props,
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the jobs table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it('displays correct number of job rows', () => {
    expect(findTableRows()).toHaveLength(mockJobsInTable.length);
  });

  it('displays job status', () => {
    expect(findStatusBadge().exists()).toBe(true);
  });

  it('displays the job stage and name', () => {
    const firstJob = mockJobsInTable[0];

    expect(findJobStage().text()).toBe(firstJob.stage.name);
    expect(findJobName().text()).toBe(firstJob.name);
  });

  it('displays the coverage for only jobs that have coverage', () => {
    const jobsThatHaveCoverage = mockJobsInTable.filter((job) => job.coverage !== null);

    jobsThatHaveCoverage.forEach((job, index) => {
      expect(findAllCoverageJobs().at(index).text()).toBe(`${job.coverage}%`);
    });
    expect(findAllCoverageJobs()).toHaveLength(jobsThatHaveCoverage.length);
  });
});
