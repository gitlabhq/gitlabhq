import { GlLoadingIcon, GlTable, GlLink, GlBadge, GlPagination, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import getJobArtifactsResponse from 'test_fixtures/graphql/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import waitForPromises from 'helpers/wait_for_promises';
import JobArtifactsTable from '~/artifacts/components/job_artifacts_table.vue';
import FeedbackBanner from '~/artifacts/components/feedback_banner.vue';
import ArtifactsTableRowDetails from '~/artifacts/components/artifacts_table_row_details.vue';
import ArtifactDeleteModal from '~/artifacts/components/artifact_delete_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import getJobArtifactsQuery from '~/artifacts/graphql/queries/get_job_artifacts.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ARCHIVE_FILE_TYPE, JOBS_PER_PAGE, I18N_FETCH_ERROR } from '~/artifacts/constants';
import { totalArtifactsSizeForJob } from '~/artifacts/utils';
import { createAlert } from '~/flash';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('JobArtifactsTable component', () => {
  let wrapper;
  let requestHandlers;

  const findBanner = () => wrapper.findComponent(FeedbackBanner);

  const findLoadingState = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(GlTable);
  const findDetailsRows = () => wrapper.findAllComponents(ArtifactsTableRowDetails);
  const findDetailsInRow = (i) =>
    findTable().findAll('tbody tr').at(i).findComponent(ArtifactsTableRowDetails);

  const findCount = () => wrapper.findByTestId('job-artifacts-count');
  const findCountAt = (i) => wrapper.findAllByTestId('job-artifacts-count').at(i);

  const findModal = () => wrapper.findComponent(GlModal);

  const findStatuses = () => wrapper.findAllByTestId('job-artifacts-job-status');
  const findSuccessfulJobStatus = () => findStatuses().at(0);
  const findFailedJobStatus = () => findStatuses().at(1);

  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findJobLink = () => findLinks().at(0);
  const findPipelineLink = () => findLinks().at(1);
  const findRefLink = () => findLinks().at(2);
  const findCommitLink = () => findLinks().at(3);

  const findSize = () => wrapper.findByTestId('job-artifacts-size');
  const findCreated = () => wrapper.findByTestId('job-artifacts-created');

  const findDownloadButton = () => wrapper.findByTestId('job-artifacts-download-button');
  const findBrowseButton = () => wrapper.findByTestId('job-artifacts-browse-button');
  const findDeleteButton = () => wrapper.findByTestId('job-artifacts-delete-button');
  const findArtifactDeleteButton = () => wrapper.findByTestId('job-artifact-row-delete-button');

  const findPagination = () => wrapper.findComponent(GlPagination);
  const setPage = async (page) => {
    findPagination().vm.$emit('input', page);
    await waitForPromises();
  };

  let enoughJobsToPaginate = [...getJobArtifactsResponse.data.project.jobs.nodes];
  while (enoughJobsToPaginate.length <= JOBS_PER_PAGE) {
    enoughJobsToPaginate = [
      ...enoughJobsToPaginate,
      ...getJobArtifactsResponse.data.project.jobs.nodes,
    ];
  }
  const getJobArtifactsResponseThatPaginates = {
    data: { project: { jobs: { nodes: enoughJobsToPaginate } } },
  };

  const job = getJobArtifactsResponse.data.project.jobs.nodes[0];
  const archiveArtifact = job.artifacts.nodes.find(
    (artifact) => artifact.fileType === ARCHIVE_FILE_TYPE,
  );

  const createComponent = (
    handlers = {
      getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponse),
    },
    data = {},
  ) => {
    requestHandlers = handlers;
    wrapper = mountExtended(JobArtifactsTable, {
      apolloProvider: createMockApollo([
        [getJobArtifactsQuery, requestHandlers.getJobArtifactsQuery],
      ]),
      provide: {
        projectPath: 'project/path',
        artifactsManagementFeedbackImagePath: 'banner/image/path',
      },
      data() {
        return data;
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders feedback banner', () => {
    createComponent();

    expect(findBanner().exists()).toBe(true);
  });

  it('when loading, shows a loading state', () => {
    createComponent();

    expect(findLoadingState().exists()).toBe(true);
  });

  it('on error, shows an alert', async () => {
    createComponent({
      getJobArtifactsQuery: jest.fn().mockRejectedValue(new Error('Error!')),
    });

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: I18N_FETCH_ERROR });
  });

  it('with data, renders the table', async () => {
    createComponent();

    await waitForPromises();

    expect(findTable().exists()).toBe(true);
  });

  describe('job details', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('shows the artifact count', () => {
      expect(findCount().text()).toBe(`${job.artifacts.nodes.length} files`);
    });

    it('shows the job status as an icon for a successful job', () => {
      expect(findSuccessfulJobStatus().findComponent(CiIcon).exists()).toBe(true);
      expect(findSuccessfulJobStatus().findComponent(GlBadge).exists()).toBe(false);
    });

    it('shows the job status as a badge for other job statuses', () => {
      expect(findFailedJobStatus().findComponent(GlBadge).exists()).toBe(true);
      expect(findFailedJobStatus().findComponent(CiIcon).exists()).toBe(false);
    });

    it('shows links to the job, pipeline, ref, and commit', () => {
      expect(findJobLink().text()).toBe(job.name);
      expect(findJobLink().attributes('href')).toBe(job.webPath);

      expect(findPipelineLink().text()).toBe(`#${getIdFromGraphQLId(job.pipeline.id)}`);
      expect(findPipelineLink().attributes('href')).toBe(job.pipeline.path);

      expect(findRefLink().text()).toBe(job.refName);
      expect(findRefLink().attributes('href')).toBe(job.refPath);

      expect(findCommitLink().text()).toBe(job.shortSha);
      expect(findCommitLink().attributes('href')).toBe(job.commitPath);
    });

    it('shows the total size of artifacts', () => {
      expect(findSize().text()).toBe(totalArtifactsSizeForJob(job));
    });

    it('shows the created time', () => {
      expect(findCreated().text()).toBe('5 years ago');
    });

    describe('row expansion', () => {
      it('toggles the visibility of the row details', async () => {
        expect(findDetailsRows().length).toBe(0);

        findCount().trigger('click');
        await waitForPromises();

        expect(findDetailsRows().length).toBe(1);

        findCount().trigger('click');
        await waitForPromises();

        expect(findDetailsRows().length).toBe(0);
      });

      it('expands and collapses jobs', async () => {
        // both jobs start collapsed
        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(false);

        findCountAt(0).trigger('click');
        await waitForPromises();

        // first job is expanded, second row has its details
        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(true);
        expect(findDetailsInRow(2).exists()).toBe(false);

        findCountAt(1).trigger('click');
        await waitForPromises();

        // both jobs are expanded, each has details below it
        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(true);
        expect(findDetailsInRow(2).exists()).toBe(false);
        expect(findDetailsInRow(3).exists()).toBe(true);

        findCountAt(0).trigger('click');
        await waitForPromises();

        // first job collapsed, second job expanded
        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(false);
        expect(findDetailsInRow(2).exists()).toBe(true);
      });

      it('keeps the job expanded when an artifact is deleted', async () => {
        findCount().trigger('click');
        await waitForPromises();

        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(true);

        findArtifactDeleteButton().trigger('click');
        await waitForPromises();

        expect(findModal().props('visible')).toBe(true);

        wrapper.findComponent(ArtifactDeleteModal).vm.$emit('primary');
        await waitForPromises();

        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(true);
      });
    });
  });

  describe('download button', () => {
    it('is a link to the download path for the archive artifact', async () => {
      createComponent();

      await waitForPromises();

      expect(findDownloadButton().attributes('href')).toBe(archiveArtifact.downloadPath);
    });

    it('is disabled when there is no download path', async () => {
      const jobWithoutDownloadPath = {
        ...job,
        archive: { downloadPath: null },
      };

      createComponent(
        { getJobArtifactsQuery: jest.fn() },
        { jobArtifacts: [jobWithoutDownloadPath] },
      );

      await waitForPromises();

      expect(findDownloadButton().attributes('disabled')).toBe('disabled');
    });
  });

  describe('browse button', () => {
    it('is a link to the browse path for the job', async () => {
      createComponent();

      await waitForPromises();

      expect(findBrowseButton().attributes('href')).toBe(job.browseArtifactsPath);
    });

    it('is disabled when there is no browse path', async () => {
      const jobWithoutBrowsePath = {
        ...job,
        browseArtifactsPath: null,
      };

      createComponent(
        { getJobArtifactsQuery: jest.fn() },
        { jobArtifacts: [jobWithoutBrowsePath] },
      );

      await waitForPromises();

      expect(findBrowseButton().attributes('disabled')).toBe('disabled');
    });
  });

  describe('delete button', () => {
    it('shows a disabled delete button for now (coming soon)', async () => {
      createComponent();

      await waitForPromises();

      expect(findDeleteButton().attributes('disabled')).toBe('disabled');
    });
  });

  describe('pagination', () => {
    const { pageInfo } = getJobArtifactsResponse.data.project.jobs;

    beforeEach(async () => {
      createComponent(
        {
          getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponseThatPaginates),
        },
        {
          count: enoughJobsToPaginate.length,
          pageInfo,
        },
      );

      await waitForPromises();
    });

    it('renders pagination and passes page props', () => {
      expect(findPagination().exists()).toBe(true);
      expect(findPagination().props()).toMatchObject({
        value: wrapper.vm.pagination.currentPage,
        prevPage: wrapper.vm.prevPage,
        nextPage: wrapper.vm.nextPage,
      });
    });

    it('updates query variables when going to previous page', () => {
      return setPage(1).then(() => {
        expect(wrapper.vm.queryVariables).toMatchObject({
          projectPath: 'project/path',
          nextPageCursor: undefined,
          prevPageCursor: pageInfo.startCursor,
        });
      });
    });

    it('updates query variables when going to next page', () => {
      return setPage(2).then(() => {
        expect(wrapper.vm.queryVariables).toMatchObject({
          lastPageSize: null,
          nextPageCursor: pageInfo.endCursor,
          prevPageCursor: '',
        });
      });
    });
  });
});
