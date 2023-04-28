import {
  GlLoadingIcon,
  GlTable,
  GlLink,
  GlBadge,
  GlPagination,
  GlModal,
  GlFormCheckbox,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import getJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import waitForPromises from 'helpers/wait_for_promises';
import JobArtifactsTable from '~/ci/artifacts/components/job_artifacts_table.vue';
import FeedbackBanner from '~/ci/artifacts/components/feedback_banner.vue';
import ArtifactsTableRowDetails from '~/ci/artifacts/components/artifacts_table_row_details.vue';
import ArtifactDeleteModal from '~/ci/artifacts/components/artifact_delete_modal.vue';
import ArtifactsBulkDelete from '~/ci/artifacts/components/artifacts_bulk_delete.vue';
import BulkDeleteModal from '~/ci/artifacts/components/bulk_delete_modal.vue';
import JobCheckbox from '~/ci/artifacts/components/job_checkbox.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import getJobArtifactsQuery from '~/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql';
import bulkDestroyArtifactsMutation from '~/ci/artifacts/graphql/mutations/bulk_destroy_job_artifacts.mutation.graphql';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import {
  ARCHIVE_FILE_TYPE,
  JOBS_PER_PAGE,
  I18N_FETCH_ERROR,
  INITIAL_CURRENT_PAGE,
  BULK_DELETE_FEATURE_FLAG,
  I18N_BULK_DELETE_ERROR,
  SELECTED_ARTIFACTS_MAX_COUNT,
} from '~/ci/artifacts/constants';
import { totalArtifactsSizeForJob } from '~/ci/artifacts/utils';
import { createAlert } from '~/alert';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('JobArtifactsTable component', () => {
  let wrapper;
  let requestHandlers;

  const mockToastShow = jest.fn();

  const findBanner = () => wrapper.findComponent(FeedbackBanner);

  const findLoadingState = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(GlTable);
  const findDetailsRows = () => wrapper.findAllComponents(ArtifactsTableRowDetails);
  const findDetailsInRow = (i) =>
    findTable().findAll('tbody tr').at(i).findComponent(ArtifactsTableRowDetails);

  const findCount = () => wrapper.findByTestId('job-artifacts-count');
  const findCountAt = (i) => wrapper.findAllByTestId('job-artifacts-count').at(i);

  const findDeleteModal = () => wrapper.findComponent(ArtifactDeleteModal);
  const findBulkDeleteModal = () => wrapper.findComponent(BulkDeleteModal);

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

  // first checkbox is a "select all", this finder should get the first job checkbox
  const findJobCheckbox = (i = 1) => wrapper.findAllComponents(GlFormCheckbox).at(i);
  const findAnyCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findBulkDelete = () => wrapper.findComponent(ArtifactsBulkDelete);
  const findBulkDeleteContainer = () => wrapper.findByTestId('bulk-delete-container');

  const findPagination = () => wrapper.findComponent(GlPagination);
  const setPage = async (page) => {
    findPagination().vm.$emit('input', page);
    await waitForPromises();
  };

  const projectId = 'some/project/id';

  let enoughJobsToPaginate = [...getJobArtifactsResponse.data.project.jobs.nodes];
  while (enoughJobsToPaginate.length <= JOBS_PER_PAGE) {
    enoughJobsToPaginate = [
      ...enoughJobsToPaginate,
      ...getJobArtifactsResponse.data.project.jobs.nodes,
    ];
  }
  const getJobArtifactsResponseThatPaginates = {
    data: {
      project: {
        jobs: {
          nodes: enoughJobsToPaginate,
          pageInfo: { ...getJobArtifactsResponse.data.project.jobs.pageInfo, hasNextPage: true },
        },
      },
    },
  };

  const job = getJobArtifactsResponse.data.project.jobs.nodes[0];
  const archiveArtifact = job.artifacts.nodes.find(
    (artifact) => artifact.fileType === ARCHIVE_FILE_TYPE,
  );
  const job2 = getJobArtifactsResponse.data.project.jobs.nodes[1];

  const destroyedCount = job.artifacts.nodes.length;
  const destroyedIds = job.artifacts.nodes.map((node) => node.id);
  const bulkDestroyMutationHandler = jest.fn().mockResolvedValue({
    data: {
      bulkDestroyJobArtifacts: { errors: [], destroyedCount, destroyedIds },
    },
  });

  const maxSelectedArtifacts = new Array(SELECTED_ARTIFACTS_MAX_COUNT).fill({});

  const createComponent = ({
    handlers = {
      getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponse),
      bulkDestroyArtifactsMutation: bulkDestroyMutationHandler,
    },
    data = {},
    canDestroyArtifacts = true,
    glFeatures = {},
  } = {}) => {
    requestHandlers = handlers;
    wrapper = mountExtended(JobArtifactsTable, {
      apolloProvider: createMockApollo([
        [getJobArtifactsQuery, requestHandlers.getJobArtifactsQuery],
        [bulkDestroyArtifactsMutation, requestHandlers.bulkDestroyArtifactsMutation],
      ]),
      provide: {
        projectPath: 'project/path',
        projectId,
        canDestroyArtifacts,
        artifactsManagementFeedbackImagePath: 'banner/image/path',
        glFeatures,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
      data() {
        return data;
      },
    });
  };

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
      handlers: {
        getJobArtifactsQuery: jest.fn().mockRejectedValue(new Error('Error!')),
      },
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
        await nextTick();

        expect(findDetailsRows().length).toBe(1);

        findCount().trigger('click');
        await nextTick();

        expect(findDetailsRows().length).toBe(0);
      });

      it('expands and collapses jobs', async () => {
        // both jobs start collapsed
        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(false);

        findCountAt(0).trigger('click');
        await nextTick();

        // first job is expanded, second row has its details
        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(true);
        expect(findDetailsInRow(2).exists()).toBe(false);

        findCountAt(1).trigger('click');
        await nextTick();

        // both jobs are expanded, each has details below it
        expect(findDetailsInRow(0).exists()).toBe(false);
        expect(findDetailsInRow(1).exists()).toBe(true);
        expect(findDetailsInRow(2).exists()).toBe(false);
        expect(findDetailsInRow(3).exists()).toBe(true);

        findCountAt(0).trigger('click');
        await nextTick();

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

        findArtifactDeleteButton().vm.$emit('click');
        await nextTick();

        expect(findDeleteModal().findComponent(GlModal).props('visible')).toBe(true);

        findDeleteModal().vm.$emit('primary');
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

      createComponent({
        handlers: { getJobArtifactsQuery: jest.fn() },
        data: { jobArtifacts: [jobWithoutDownloadPath] },
      });

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

      createComponent({
        handlers: { getJobArtifactsQuery: jest.fn() },
        data: { jobArtifacts: [jobWithoutBrowsePath] },
      });

      await waitForPromises();

      expect(findBrowseButton().attributes('disabled')).toBe('disabled');
    });
  });

  describe('delete button', () => {
    const artifactsFromJob = job.artifacts.nodes.map((node) => node.id);

    describe('with delete permission and bulk delete feature flag enabled', () => {
      beforeEach(async () => {
        createComponent({
          canDestroyArtifacts: true,
          glFeatures: { [BULK_DELETE_FEATURE_FLAG]: true },
        });

        await waitForPromises();
      });

      it('opens the confirmation modal with the artifacts from the job', async () => {
        await findDeleteButton().vm.$emit('click');

        expect(findBulkDeleteModal().props()).toMatchObject({
          visible: true,
          artifactsToDelete: artifactsFromJob,
        });
      });

      it('on confirm, deletes the artifacts from the job and shows a toast', async () => {
        findDeleteButton().vm.$emit('click');
        findBulkDeleteModal().vm.$emit('primary');

        expect(bulkDestroyMutationHandler).toHaveBeenCalledWith({
          projectId: convertToGraphQLId(TYPENAME_PROJECT, projectId),
          ids: artifactsFromJob,
        });

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          `${artifactsFromJob.length} selected artifacts deleted`,
        );
      });

      it('does not clear selected artifacts on success', async () => {
        // select job 2 via checkbox
        findJobCheckbox(2).vm.$emit('input', true);

        // click delete button job 1
        findDeleteButton().vm.$emit('click');

        // job 2's artifacts should still be selected
        expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual(
          job2.artifacts.nodes.map((node) => node.id),
        );

        // confirm delete
        findBulkDeleteModal().vm.$emit('primary');

        // job 1's artifacts should be deleted
        expect(bulkDestroyMutationHandler).toHaveBeenCalledWith({
          projectId: convertToGraphQLId(TYPENAME_PROJECT, projectId),
          ids: artifactsFromJob,
        });

        await waitForPromises();

        // job 2's artifacts should still be selected
        expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual(
          job2.artifacts.nodes.map((node) => node.id),
        );
      });
    });

    it('shows an alert and does not clear selected artifacts on error', async () => {
      createComponent({
        canDestroyArtifacts: true,
        glFeatures: { [BULK_DELETE_FEATURE_FLAG]: true },
        handlers: {
          getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponse),
          bulkDestroyArtifactsMutation: jest.fn().mockRejectedValue(),
        },
      });
      await waitForPromises();

      // select job 2 via checkbox
      findJobCheckbox(2).vm.$emit('input', true);

      // click delete button job 1
      findDeleteButton().vm.$emit('click');

      // confirm delete
      findBulkDeleteModal().vm.$emit('primary');

      await waitForPromises();

      // job 2's artifacts should still be selected
      expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual(
        job2.artifacts.nodes.map((node) => node.id),
      );
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Error),
        message: I18N_BULK_DELETE_ERROR,
      });
    });

    it('is disabled when bulk delete feature flag is disabled', async () => {
      createComponent({
        canDestroyArtifacts: true,
        glFeatures: { [BULK_DELETE_FEATURE_FLAG]: false },
      });

      await waitForPromises();

      expect(findDeleteButton().attributes('disabled')).toBe('disabled');
    });

    it('is hidden when user does not have delete permission', async () => {
      createComponent({
        canDestroyArtifacts: false,
        glFeatures: { [BULK_DELETE_FEATURE_FLAG]: false },
      });

      await waitForPromises();

      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('bulk delete', () => {
    const selectedArtifacts = job.artifacts.nodes.map((node) => node.id);

    describe('with permission and feature flag enabled', () => {
      beforeEach(async () => {
        createComponent({
          canDestroyArtifacts: true,
          glFeatures: { [BULK_DELETE_FEATURE_FLAG]: true },
        });

        await waitForPromises();
      });

      it('shows selected artifacts when a job is checked', async () => {
        expect(findBulkDeleteContainer().exists()).toBe(false);

        await findJobCheckbox().vm.$emit('input', true);

        expect(findBulkDeleteContainer().exists()).toBe(true);
        expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual(selectedArtifacts);
      });

      it('disappears when selected artifacts are cleared', async () => {
        await findJobCheckbox().vm.$emit('input', true);

        expect(findBulkDeleteContainer().exists()).toBe(true);

        await findBulkDelete().vm.$emit('clearSelectedArtifacts');

        expect(findBulkDeleteContainer().exists()).toBe(false);
      });

      it('shows a modal to confirm bulk delete', async () => {
        findJobCheckbox().vm.$emit('input', true);
        findBulkDelete().vm.$emit('showBulkDeleteModal');

        await nextTick();

        expect(findBulkDeleteModal().props('visible')).toBe(true);
      });

      it('deletes the selected artifacts and shows a toast', async () => {
        findJobCheckbox().vm.$emit('input', true);
        findBulkDelete().vm.$emit('showBulkDeleteModal');
        findBulkDeleteModal().vm.$emit('primary');

        expect(bulkDestroyMutationHandler).toHaveBeenCalledWith({
          projectId: convertToGraphQLId(TYPENAME_PROJECT, projectId),
          ids: selectedArtifacts,
        });

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          `${selectedArtifacts.length} selected artifacts deleted`,
        );
      });

      it('clears selected artifacts on success', async () => {
        findJobCheckbox().vm.$emit('input', true);
        findBulkDelete().vm.$emit('showBulkDeleteModal');
        findBulkDeleteModal().vm.$emit('primary');

        await waitForPromises();

        expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual([]);
      });
    });

    describe('when the selected artifacts limit is reached', () => {
      beforeEach(async () => {
        createComponent({
          canDestroyArtifacts: true,
          glFeatures: { [BULK_DELETE_FEATURE_FLAG]: true },
          data: { selectedArtifacts: maxSelectedArtifacts },
        });

        await nextTick();
      });

      it('passes isSelectedArtifactsLimitReached to bulk delete', () => {
        expect(findBulkDelete().props('isSelectedArtifactsLimitReached')).toBe(true);
      });

      it('passes isSelectedArtifactsLimitReached to job checkbox', () => {
        expect(wrapper.findComponent(JobCheckbox).props('isSelectedArtifactsLimitReached')).toBe(
          true,
        );
      });

      it('passes isSelectedArtifactsLimitReached to table row details', async () => {
        findCount().trigger('click');
        await nextTick();

        expect(findDetailsInRow(1).props('isSelectedArtifactsLimitReached')).toBe(true);
      });
    });

    it('shows an alert and does not clear selected artifacts on error', async () => {
      createComponent({
        canDestroyArtifacts: true,
        glFeatures: { [BULK_DELETE_FEATURE_FLAG]: true },
        handlers: {
          getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponse),
          bulkDestroyArtifactsMutation: jest.fn().mockRejectedValue(),
        },
      });

      await waitForPromises();

      findJobCheckbox().vm.$emit('input', true);
      findBulkDelete().vm.$emit('showBulkDeleteModal');
      findBulkDeleteModal().vm.$emit('primary');

      await waitForPromises();

      expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual(selectedArtifacts);
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Error),
        message: I18N_BULK_DELETE_ERROR,
      });
    });

    it('shows no checkboxes without permission', async () => {
      createComponent({
        canDestroyArtifacts: false,
        glFeatures: { [BULK_DELETE_FEATURE_FLAG]: true },
      });

      await waitForPromises();

      expect(findAnyCheckbox().exists()).toBe(false);
    });

    it('shows no checkboxes with feature flag disabled', async () => {
      createComponent({
        canDestroyArtifacts: true,
        glFeatures: { [BULK_DELETE_FEATURE_FLAG]: false },
      });

      await waitForPromises();

      expect(findAnyCheckbox().exists()).toBe(false);
    });
  });

  describe('pagination', () => {
    const { pageInfo } = getJobArtifactsResponseThatPaginates.data.project.jobs;
    const query = jest.fn().mockResolvedValue(getJobArtifactsResponseThatPaginates);

    beforeEach(async () => {
      createComponent({
        handlers: {
          getJobArtifactsQuery: query,
        },
        data: { pageInfo },
      });

      await nextTick();
    });

    it('renders pagination and passes page props', () => {
      expect(findPagination().props()).toMatchObject({
        value: INITIAL_CURRENT_PAGE,
        prevPage: Number(pageInfo.hasPreviousPage),
        nextPage: Number(pageInfo.hasNextPage),
      });

      expect(query).toHaveBeenCalledWith({
        projectPath: 'project/path',
        firstPageSize: JOBS_PER_PAGE,
        lastPageSize: null,
        nextPageCursor: '',
        prevPageCursor: '',
      });
    });

    it('updates query variables when going to previous page', async () => {
      await setPage(1);

      expect(query).toHaveBeenLastCalledWith({
        projectPath: 'project/path',
        firstPageSize: null,
        lastPageSize: JOBS_PER_PAGE,
        prevPageCursor: pageInfo.startCursor,
      });
      expect(findPagination().props('value')).toEqual(1);
    });

    it('updates query variables when going to next page', async () => {
      await setPage(2);

      expect(query).toHaveBeenLastCalledWith({
        projectPath: 'project/path',
        firstPageSize: JOBS_PER_PAGE,
        lastPageSize: null,
        prevPageCursor: '',
        nextPageCursor: pageInfo.endCursor,
      });
      expect(findPagination().props('value')).toEqual(2);
    });
  });
});
