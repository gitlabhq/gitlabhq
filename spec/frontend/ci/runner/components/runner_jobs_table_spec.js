import { GlTableLite } from '@gitlab/ui';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerJobsTable from '~/ci/runner/components/runner_jobs_table.vue';
import { useFakeDate } from 'helpers/fake_date';
import { runnerJobsData } from '../mock_data';

const mockJobs = runnerJobsData.data.runner.jobs.nodes;

describe('RunnerJobsTable', () => {
  let wrapper;
  const mockNow = '2021-01-15T12:00:00Z';
  const mockOneHourAgo = '2021-01-15T11:00:00Z';

  useFakeDate(mockNow);

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findHeaders = () => wrapper.findAll('th');
  const findRows = () => wrapper.findAll('[data-testid^="job-row-"]');
  const findCell = ({ field }) =>
    extendedWrapper(findRows().at(0).find(`[data-testid="td-${field}"]`));

  const createComponent = ({ props = {} } = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(RunnerJobsTable, {
      propsData: {
        jobs: mockJobs,
        ...props,
      },
      stubs: {
        GlTableLite,
      },
    });
  };

  it('Sets job id as a row key', () => {
    createComponent();

    expect(findTable().attributes('primarykey')).toBe('id');
  });

  describe('Table data', () => {
    beforeEach(() => {
      createComponent({}, mountExtended);
    });

    it('Displays headers', () => {
      const headerLabels = findHeaders().wrappers.map((w) => w.text());

      expect(headerLabels).toEqual([
        'Status',
        'Job',
        'Project',
        'Commit',
        'Finished at',
        'Duration',
        'Queued',
        'Tags',
      ]);
    });

    it('Displays a list of jobs', () => {
      expect(findRows()).toHaveLength(1);
    });

    it('Displays details of a job', () => {
      const { id, detailedStatus, project, shortSha, commitPath } = mockJobs[0];

      expect(findCell({ field: 'status' }).text()).toMatchInterpolatedText(detailedStatus.text);

      expect(findCell({ field: 'job' }).text()).toContain(`#${getIdFromGraphQLId(id)}`);
      expect(findCell({ field: 'job' }).find('a').attributes('href')).toBe(
        detailedStatus.detailsPath,
      );

      expect(findCell({ field: 'project' }).text()).toBe(project.name);
      expect(findCell({ field: 'project' }).find('a').attributes('href')).toBe(project.webUrl);

      expect(findCell({ field: 'commit' }).text()).toBe(shortSha);
      expect(findCell({ field: 'commit' }).find('a').attributes('href')).toBe(commitPath);
    });
  });

  describe('Table data formatting', () => {
    let mockJobsCopy;

    beforeEach(() => {
      mockJobsCopy = [
        {
          ...mockJobs[0],
        },
      ];
    });

    it('Formats finishedAt time', () => {
      mockJobsCopy[0].finishedAt = mockOneHourAgo;

      createComponent({ props: { jobs: mockJobsCopy } }, mountExtended);

      expect(findCell({ field: 'finished_at' }).text()).toBe('1 hour ago');
    });

    it('Formats duration time', () => {
      mockJobsCopy[0].duration = 60;

      createComponent({ props: { jobs: mockJobsCopy } }, mountExtended);

      expect(findCell({ field: 'duration' }).text()).toBe('00:01:00');
    });

    it('Formats queued time', () => {
      mockJobsCopy[0].queuedDuration = 30;

      createComponent({ props: { jobs: mockJobsCopy } }, mountExtended);

      expect(findCell({ field: 'queued' }).text()).toBe('00:00:30');
    });

    it('Formats tags', () => {
      mockJobsCopy[0].tags = ['tag-1', 'tag-2'];

      createComponent({ props: { jobs: mockJobsCopy } }, mountExtended);

      expect(findCell({ field: 'tags' }).text()).toMatchInterpolatedText('tag-1 tag-2');
    });
  });
});
