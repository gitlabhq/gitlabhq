import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JobsTable from '~/ci/jobs_page/components/jobs_table.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { DEFAULT_FIELDS_ADMIN } from '~/ci/admin/jobs_table/constants';
import ProjectCell from '~/ci/admin/jobs_table/components/cells/project_cell.vue';
import RunnerCell from '~/ci/admin/jobs_table/components/cells/runner_cell.vue';
import { mockJobsNodes, mockAllJobsNodes } from 'jest/ci/jobs_mock_data';

describe('Jobs Table', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findEmptyResult = () => wrapper.findComponent(EmptyResult);
  const findCiIcon = () => wrapper.findComponent(CiIcon);
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
      expect(findCiIcon().exists()).toBe(true);
    });

    it('displays the job stage, id and name', () => {
      const [firstJob] = mockJobsNodes;

      expect(findJobStage().text()).toBe(`Stage: ${firstJob.stage.name}`);
      expect(findJobName().text()).toBe(`#${getIdFromGraphQLId(firstJob.id)}: ${firstJob.name}`);
    });

    it('displays the coverage for only jobs that have coverage', () => {
      const jobsThatHaveCoverage = mockJobsNodes.filter((job) => job.coverage !== null);

      jobsThatHaveCoverage.forEach((job, index) => {
        expect(findAllCoverageJobs().at(index).text()).toBe(`${job.coverage}%`);
      });
      expect(findAllCoverageJobs()).toHaveLength(jobsThatHaveCoverage.length);
    });

    describe('when stage of a job is missing', () => {
      it('shows no stage', () => {
        const stagelessJob = { ...mockJobsNodes[0], stage: null };
        createComponent({ jobs: [stagelessJob] });

        expect(findJobStage().exists()).toBe(false);
      });
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

  describe('EmptyResult component', () => {
    it('does not display Empty result with jobs defined', () => {
      createComponent({ jobs: mockJobsNodes });
      expect(findEmptyResult().exists()).toBe(false);
    });

    it('displays Empty result when there are no jobs', () => {
      createComponent({ jobs: [] });
      expect(findEmptyResult().exists()).toBe(true);
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
