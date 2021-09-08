import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import JobCell from '~/jobs/components/table/cells/job_cell.vue';
import { mockJobsInTable } from '../../../mock_data';

const mockJob = mockJobsInTable[0];
const mockJobCreatedByTag = mockJobsInTable[1];
const mockJobLimitedAccess = mockJobsInTable[2];
const mockStuckJob = mockJobsInTable[3];

describe('Job Cell', () => {
  let wrapper;

  const findJobIdLink = () => wrapper.findByTestId('job-id-link');
  const findJobIdNoLink = () => wrapper.findByTestId('job-id-limited-access');
  const findJobRef = () => wrapper.findByTestId('job-ref');
  const findJobSha = () => wrapper.findByTestId('job-sha');
  const findLabelIcon = () => wrapper.findByTestId('label-icon');
  const findForkIcon = () => wrapper.findByTestId('fork-icon');
  const findStuckIcon = () => wrapper.findByTestId('stuck-icon');
  const findAllTagBadges = () => wrapper.findAllByTestId('job-tag-badge');

  const findBadgeById = (id) => wrapper.findByTestId(id);

  const createComponent = (jobData = mockJob) => {
    wrapper = extendedWrapper(
      shallowMount(JobCell, {
        propsData: {
          job: jobData,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Job Id', () => {
    it('displays the job id and links to the job', () => {
      createComponent();

      const expectedJobId = `#${getIdFromGraphQLId(mockJob.id)}`;

      expect(findJobIdLink().text()).toBe(expectedJobId);
      expect(findJobIdLink().attributes('href')).toBe(mockJob.detailedStatus.detailsPath);
      expect(findJobIdNoLink().exists()).toBe(false);
    });

    it('display the job id with no link', () => {
      createComponent(mockJobLimitedAccess);

      const expectedJobId = `#${getIdFromGraphQLId(mockJobLimitedAccess.id)}`;

      expect(findJobIdNoLink().text()).toBe(expectedJobId);
      expect(findJobIdNoLink().exists()).toBe(true);
      expect(findJobIdLink().exists()).toBe(false);
    });
  });

  describe('Ref of the job', () => {
    it('displays the ref name and links to the ref', () => {
      createComponent();

      expect(findJobRef().text()).toBe(mockJob.refName);
      expect(findJobRef().attributes('href')).toBe(mockJob.refPath);
    });

    it('displays fork icon when job is not created by tag', () => {
      createComponent();

      expect(findForkIcon().exists()).toBe(true);
      expect(findLabelIcon().exists()).toBe(false);
    });

    it('displays label icon when job is created by a tag', () => {
      createComponent(mockJobCreatedByTag);

      expect(findLabelIcon().exists()).toBe(true);
      expect(findForkIcon().exists()).toBe(false);
    });
  });

  describe('Commit of the job', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the sha and links to the commit', () => {
      expect(findJobSha().text()).toBe(mockJob.shortSha);
      expect(findJobSha().attributes('href')).toBe(mockJob.commitPath);
    });
  });

  describe('Job badges', () => {
    it('displays tags of the job', () => {
      const mockJobWithTags = {
        tags: ['tag-1', 'tag-2', 'tag-3'],
      };

      createComponent(mockJobWithTags);

      expect(findAllTagBadges()).toHaveLength(mockJobWithTags.tags.length);
    });

    it.each`
      testId                   | text
      ${'manual-job-badge'}    | ${'manual'}
      ${'triggered-job-badge'} | ${'triggered'}
      ${'fail-job-badge'}      | ${'allowed to fail'}
      ${'delayed-job-badge'}   | ${'delayed'}
    `('displays the static $text badge', ({ testId, text }) => {
      createComponent({
        manualJob: true,
        triggered: true,
        allowFailure: true,
        scheduledAt: '2021-03-09T14:58:50+00:00',
      });

      expect(findBadgeById(testId).exists()).toBe(true);
      expect(findBadgeById(testId).text()).toBe(text);
    });
  });

  describe('Job icons', () => {
    it('stuck icon is not shown if job is not stuck', () => {
      createComponent();

      expect(findStuckIcon().exists()).toBe(false);
    });

    it('stuck icon is shown if job is stuck', () => {
      createComponent(mockStuckJob);

      expect(findStuckIcon().exists()).toBe(true);
      expect(findStuckIcon().attributes('name')).toBe('warning');
    });
  });
});
