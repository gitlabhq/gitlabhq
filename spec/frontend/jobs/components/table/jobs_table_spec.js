import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import { DEFAULT_FIELDS_ADMIN } from '~/pages/admin/jobs/components/constants';
import ProjectCell from '~/pages/admin/jobs/components/table/cell/project_cell.vue';
import RunnerCell from '~/pages/admin/jobs/components/table/cells/runner_cell.vue';
import { mockJobsNodes, mockAllJobsNodes } from '../../mock_data';

describe('Jobs Table', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findCiBadgeLink = () => wrapper.findComponent(CiBadgeLink);
  const findTableRows = () => wrapper.findAllByTestId('jobs-table-row');
  const findJobStage = () => wrapper.findByTestId('job-stage-name');
  const findJobName = () => wrapper.findByTestId('job-name');
  const findJobProject = () => wrapper.findComponent(ProjectCell);
  const findJobRunner = () => wrapper.findComponent(RunnerCell);
  const findAllCoverageJobs = () => wrapper.findAllByTestId('job-coverage');

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(JobsTable, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  describe('jobs table', () => {
    beforeEach(() => {
      createComponent({ jobs: mockJobsNodes });
    });

    it('displays the jobs table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('displays correct number of job rows', () => {
      expect(findTableRows()).toHaveLength(mockJobsNodes.length);
    });

    it('displays job status', () => {
      expect(findCiBadgeLink().exists()).toBe(true);
    });

    it('displays the job stage and name', () => {
      const [firstJob] = mockJobsNodes;

      expect(findJobStage().text()).toBe(firstJob.stage.name);
      expect(findJobName().text()).toBe(firstJob.name);
    });

    it('displays the coverage for only jobs that have coverage', () => {
      const jobsThatHaveCoverage = mockJobsNodes.filter((job) => job.coverage !== null);

      jobsThatHaveCoverage.forEach((job, index) => {
        expect(findAllCoverageJobs().at(index).text()).toBe(`${job.coverage}%`);
      });
      expect(findAllCoverageJobs()).toHaveLength(jobsThatHaveCoverage.length);
    });
  });

  describe('regular user', () => {
    beforeEach(() => {
      createComponent({ jobs: mockJobsNodes });
    });

    it('hides the job runner', () => {
      expect(findJobRunner().exists()).toBe(false);
    });

    it('hides the job project link', () => {
      expect(findJobProject().exists()).toBe(false);
    });
  });

  describe('admin mode', () => {
    beforeEach(() => {
      createComponent({ jobs: mockAllJobsNodes, tableFields: DEFAULT_FIELDS_ADMIN, admin: true });
    });

    it('displays the runner cell', () => {
      expect(findJobRunner().exists()).toBe(true);
    });

    it('displays the project cell', () => {
      expect(findJobProject().exists()).toBe(true);
    });

    it('displays correct number of job rows', () => {
      expect(findTableRows()).toHaveLength(mockAllJobsNodes.length);
    });
  });
});
