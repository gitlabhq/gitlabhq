import {
  GlSkeletonLoader,
  GlTable,
  GlLink,
  GlPagination,
  GlPopover,
  GlModal,
  GlFormCheckbox,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// Fixtures located in spec/frontend/fixtures/job_artifacts.rb
import getJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import waitForPromises from 'helpers/wait_for_promises';
import JobArtifactsTable from '~/ci/artifacts/components/job_artifacts_table.vue';
import ArtifactsTableRowDetails from '~/ci/artifacts/components/artifacts_table_row_details.vue';
import ArtifactDeleteModal from '~/ci/artifacts/components/artifact_delete_modal.vue';
import ArtifactsBulkDelete from '~/ci/artifacts/components/artifacts_bulk_delete.vue';
import BulkDeleteModal from '~/ci/artifacts/components/bulk_delete_modal.vue';
import JobCheckbox from '~/ci/artifacts/components/job_checkbox.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import getJobArtifactsQuery from '~/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql';
import bulkDestroyArtifactsMutation from '~/ci/artifacts/graphql/mutations/bulk_destroy_job_artifacts.mutation.graphql';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import {
  ARCHIVE_FILE_TYPE,
  JOBS_PER_PAGE,
  I18N_FETCH_ERROR,
  INITIAL_CURRENT_PAGE,
  I18N_BULK_DELETE_ERROR,
} from '~/ci/artifacts/constants';
import { totalArtifactsSizeForJob } from '~/ci/artifacts/utils';
import { createAlert } from '~/alert';
import { jobArtifactsResponseWithSecurityFiles } from './constants';

const jobArtifactsCountLimit = 100;

jest.mock('~/alert');

Vue.use(VueApollo);

describe('JobArtifactsTable component', () => {
  let wrapper;
  let requestHandlers;

  const mockToastShow = jest.fn();

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
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
  const findCiIcon = () => findSuccessfulJobStatus().findComponent(CiIcon);

  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findJobLink = () => findLinks().at(0);
  const findPipelineLink = () => findLinks().at(1);
  const findCommitLink = () => findLinks().at(2);
  const findRefLink = () => findLinks().at(3);

  const findSize = () => wrapper.findByTestId('job-artifacts-size');
  const findCreated = () => wrapper.findByTestId('job-artifacts-created');

  const findDownloadButton = () => wrapper.findByTestId('job-artifacts-download-button');
  const findBrowseButton = () => wrapper.findByTestId('job-artifacts-browse-button');
  const findDeleteButton = () => wrapper.findByTestId('job-artifacts-delete-button');
  const findArtifactDeleteButton = () => wrapper.findByTestId('job-artifact-row-delete-button');

  // first checkbox is the "select all" checkbox in the table header
  const findSelectAllCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findSelectAllCheckboxChecked = () => findSelectAllCheckbox().find('input').element.checked;
  const findSelectAllCheckboxIndeterminate = () =>
    findSelectAllCheckbox().find('input').element.indeterminate;
  const findSelectAllCheckboxDisabled = () =>
    findSelectAllCheckbox().find('input').element.disabled;
  const toggleSelectAllCheckbox = () =>
    findSelectAllCheckbox().vm.$emit('change', !findSelectAllCheckboxChecked());

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

  const findVisibleFileTypeBadge = () => wrapper.findByTestId('visible-file-type-badge');
  const findPopoverText = () => wrapper.findByTestId('file-types-popover-text');
  const findAllRemainingFileTypeBadges = () =>
    wrapper.findAllByTestId('remaining-file-type-badges');
  const findPopover = () => wrapper.findComponent(GlPopover);

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
  const emptyJob = {
    ...job,
    artifacts: { nodes: [] },
  };

  const getJobArtifactsResponseWithEmptyJob = {
    data: {
      ...getJobArtifactsResponse.data,
      project: {
        ...getJobArtifactsResponse.data.project,
        jobs: {
          nodes: [emptyJob],
          pageInfo: { ...getJobArtifactsResponse.data.project.jobs.pageInfo },
        },
      },
    },
  };

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

  const allArtifacts = getJobArtifactsResponse.data.project.jobs.nodes
    .map((jobNode) => jobNode.artifacts.nodes.map((artifactNode) => artifactNode.id))
    .reduce((artifacts, jobArtifacts) => artifacts.concat(jobArtifacts));

  const maxSelectedArtifacts = new Array(jobArtifactsCountLimit).fill('artifact-id');
  const maxSelectedArtifactsIncludingCurrentPage = [
    ...allArtifacts,
    ...new Array(jobArtifactsCountLimit - allArtifacts.length).fill('artifact-id'),
  ];

  const createComponent = ({
    handlers = {
      getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponse),
      bulkDestroyArtifactsMutation: bulkDestroyMutationHandler,
    },
    data = {},
    canDestroyArtifacts = true,
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
        jobArtifactsCountLimit,
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

  it('when loading, shows a skeleton loader', () => {
    createComponent();

    expect(findTable().attributes('aria-busy')).toBe('true');
    expect(findSkeletonLoader().exists()).toBe(true);
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

    expect(findTable().attributes('aria-busy')).toBe('false');
    expect(findSkeletonLoader().exists()).toBe(false);
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
      expect(findCiIcon().props()).toMatchObject({
        status: {
          text: 'Passed',
          icon: 'status_success',
        },
        showStatusText: false,
      });
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
        hasArtifacts: true,
        archive: { downloadPath: null },
      };

      createComponent({
        handlers: { getJobArtifactsQuery: jest.fn() },
        data: { jobArtifacts: [jobWithoutDownloadPath] },
      });

      await waitForPromises();

      expect(findDownloadButton().attributes('disabled')).toBeDefined();
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
        hasArtifacts: true,
        browseArtifactsPath: null,
      };

      createComponent({
        handlers: { getJobArtifactsQuery: jest.fn() },
        data: { jobArtifacts: [jobWithoutBrowsePath] },
      });

      await waitForPromises();

      expect(findBrowseButton().attributes('disabled')).toBeDefined();
    });

    it('is disabled when job has no metadata.gz', async () => {
      const jobWithoutMetadata = {
        ...job,
        hasArtifacts: true,
        artifacts: { nodes: [archiveArtifact] },
      };

      createComponent({
        handlers: { getJobArtifactsQuery: jest.fn() },
        data: { jobArtifacts: [jobWithoutMetadata] },
      });

      await waitForPromises();

      expect(findBrowseButton().attributes('disabled')).toBe('disabled');
    });

    it('is disabled when job has no artifacts', async () => {
      const jobWithoutArtifacts = {
        ...job,
        hasArtifacts: false,
        artifacts: { nodes: [] },
      };

      createComponent({
        handlers: { getJobArtifactsQuery: jest.fn() },
        data: { jobArtifacts: [jobWithoutArtifacts] },
      });

      await waitForPromises();

      expect(findBrowseButton().attributes('disabled')).toBe('disabled');
    });
  });

  describe('delete button', () => {
    const artifactsFromJob = job.artifacts.nodes.map((node) => node.id);

    beforeEach(async () => {
      createComponent({
        canDestroyArtifacts: true,
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
      findJobCheckbox(2).vm.$emit('change', true);

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

    it('shows an alert and does not clear selected artifacts on error', async () => {
      createComponent({
        canDestroyArtifacts: true,
        handlers: {
          getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponse),
          bulkDestroyArtifactsMutation: jest.fn().mockRejectedValue(),
        },
      });
      await waitForPromises();

      // select job 2 via checkbox
      findJobCheckbox(2).vm.$emit('change', true);

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

    it('is hidden when user does not have delete permission', async () => {
      createComponent({
        canDestroyArtifacts: false,
      });

      await waitForPromises();

      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('bulk delete', () => {
    const selectedArtifacts = job.artifacts.nodes.map((node) => node.id);

    beforeEach(async () => {
      createComponent({
        canDestroyArtifacts: true,
      });

      await waitForPromises();
    });

    it('shows selected artifacts when a job is checked', async () => {
      expect(findBulkDeleteContainer().exists()).toBe(false);

      await findJobCheckbox().vm.$emit('change', true);

      expect(findBulkDeleteContainer().exists()).toBe(true);
      expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual(selectedArtifacts);
    });

    it('disappears when selected artifacts are cleared', async () => {
      await findJobCheckbox().vm.$emit('change', true);

      expect(findBulkDeleteContainer().exists()).toBe(true);

      await findBulkDelete().vm.$emit('clearSelectedArtifacts');

      expect(findBulkDeleteContainer().exists()).toBe(false);
    });

    it('shows a modal to confirm bulk delete', async () => {
      findJobCheckbox().vm.$emit('change', true);
      findBulkDelete().vm.$emit('showBulkDeleteModal');

      await nextTick();

      expect(findBulkDeleteModal().props('visible')).toBe(true);
    });

    it('deletes the selected artifacts and shows a toast', async () => {
      findJobCheckbox().vm.$emit('change', true);
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
      findJobCheckbox().vm.$emit('change', true);
      findBulkDelete().vm.$emit('showBulkDeleteModal');
      findBulkDeleteModal().vm.$emit('primary');

      await waitForPromises();

      expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual([]);
    });

    describe('select all checkbox', () => {
      describe('when no artifacts are selected', () => {
        it('is not checked', () => {
          expect(findSelectAllCheckboxChecked()).toBe(false);
          expect(findSelectAllCheckboxIndeterminate()).toBe(false);
        });

        it('selects all artifacts when toggled', async () => {
          toggleSelectAllCheckbox();

          await nextTick();

          expect(findSelectAllCheckboxChecked()).toBe(true);
          expect(findSelectAllCheckboxIndeterminate()).toBe(false);
          expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual(allArtifacts);
        });
      });

      describe('when some artifacts are selected', () => {
        beforeEach(async () => {
          findJobCheckbox().vm.$emit('change', true);

          await nextTick();
        });

        it('is indeterminate', () => {
          expect(findSelectAllCheckboxChecked()).toBe(true);
          expect(findSelectAllCheckboxIndeterminate()).toBe(true);
        });

        it('deselects all artifacts when toggled', async () => {
          toggleSelectAllCheckbox();

          await nextTick();

          expect(findSelectAllCheckboxChecked()).toBe(false);
          expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual([]);
        });
      });

      describe('when all artifacts are selected', () => {
        beforeEach(async () => {
          findJobCheckbox(1).vm.$emit('change', true);
          findJobCheckbox(2).vm.$emit('change', true);

          await nextTick();
        });

        it('is checked', () => {
          expect(findSelectAllCheckboxChecked()).toBe(true);
          expect(findSelectAllCheckboxIndeterminate()).toBe(false);
        });

        it('deselects all artifacts when toggled', async () => {
          toggleSelectAllCheckbox();

          await nextTick();

          expect(findSelectAllCheckboxChecked()).toBe(false);
          expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual([]);
        });
      });

      describe('when an artifact is selected on another page', () => {
        const otherPageArtifact = { id: 'gid://gitlab/Ci::JobArtifact/some/other/id' };

        beforeEach(async () => {
          // expand the first job row to access the details component
          findCount().trigger('click');

          await nextTick();

          // mock the selection of an artifact on another page by emitting a select event
          findDetailsInRow(1).vm.$emit('selectArtifact', otherPageArtifact, true);
        });

        it('is not checked even though an artifact is selected', () => {
          expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual([otherPageArtifact.id]);
          expect(findSelectAllCheckboxChecked()).toBe(false);
          expect(findSelectAllCheckboxIndeterminate()).toBe(false);
        });

        it('only toggles selection of visible artifacts, leaving the other artifact selected', async () => {
          toggleSelectAllCheckbox();

          await nextTick();

          expect(findSelectAllCheckboxChecked()).toBe(true);
          expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual([
            otherPageArtifact.id,
            ...allArtifacts,
          ]);

          toggleSelectAllCheckbox();

          await nextTick();

          expect(findSelectAllCheckboxChecked()).toBe(false);
          expect(findBulkDelete().props('selectedArtifacts')).toStrictEqual([otherPageArtifact.id]);
        });
      });
    });

    describe('select all checkbox respects selected artifacts limit', () => {
      describe('when selecting all visible artifacts would exceed the limit', () => {
        const selectedArtifactsLength = jobArtifactsCountLimit - 1;

        beforeEach(async () => {
          createComponent({
            canDestroyArtifacts: true,
            data: {
              selectedArtifacts: new Array(selectedArtifactsLength).fill('artifact-id'),
            },
          });

          await nextTick();
        });

        it('selects only up to the limit', async () => {
          expect(findSelectAllCheckboxChecked()).toBe(false);
          expect(findBulkDelete().props('selectedArtifacts')).toHaveLength(selectedArtifactsLength);

          toggleSelectAllCheckbox();

          await nextTick();

          expect(findSelectAllCheckboxChecked()).toBe(true);
          expect(findBulkDelete().props('selectedArtifacts')).toHaveLength(jobArtifactsCountLimit);
          expect(findBulkDelete().props('selectedArtifacts')).not.toContain(
            allArtifacts[allArtifacts.length - 1],
          );
        });
      });

      describe('when limit has been reached without artifacts on the current page', () => {
        beforeEach(async () => {
          createComponent({
            canDestroyArtifacts: true,
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

        it('disables the select all checkbox', () => {
          expect(findSelectAllCheckboxDisabled()).toBe(true);
        });
      });

      describe('when limit has been reached including artifacts on the current page', () => {
        beforeEach(async () => {
          createComponent({
            canDestroyArtifacts: true,
            data: {
              selectedArtifacts: maxSelectedArtifactsIncludingCurrentPage,
            },
          });

          await nextTick();
        });

        describe('the select all checkbox', () => {
          it('is checked', () => {
            expect(findSelectAllCheckboxChecked()).toBe(true);
            expect(findSelectAllCheckboxIndeterminate()).toBe(false);
          });

          it('deselects all artifacts when toggled', async () => {
            expect(findBulkDelete().props('selectedArtifacts')).toHaveLength(
              jobArtifactsCountLimit,
            );

            toggleSelectAllCheckbox();

            await nextTick();

            expect(findSelectAllCheckboxChecked()).toBe(false);
            expect(findBulkDelete().props('selectedArtifacts')).toHaveLength(
              jobArtifactsCountLimit - allArtifacts.length,
            );
          });
        });
      });
    });

    it('shows an alert and does not clear selected artifacts on error', async () => {
      createComponent({
        canDestroyArtifacts: true,
        handlers: {
          getJobArtifactsQuery: jest.fn().mockResolvedValue(getJobArtifactsResponse),
          bulkDestroyArtifactsMutation: jest.fn().mockRejectedValue(),
        },
      });

      await waitForPromises();

      findJobCheckbox().vm.$emit('change', true);
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
      });

      await waitForPromises();

      expect(findAnyCheckbox().exists()).toBe(false);
    });
  });

  describe('refetch behavior', () => {
    describe('without no empty jobs', () => {
      const query = jest.fn().mockResolvedValue(getJobArtifactsResponse);

      beforeEach(async () => {
        createComponent({
          handlers: {
            getJobArtifactsQuery: query,
          },
        });

        await waitForPromises();
      });

      it('only fetches artifacts once', () => {
        expect(query).toHaveBeenCalledTimes(1);
      });
    });

    describe('with an empty job', () => {
      const query = jest
        .fn()
        .mockResolvedValueOnce(getJobArtifactsResponseWithEmptyJob)
        .mockResolvedValue(getJobArtifactsResponse);

      beforeEach(async () => {
        createComponent({
          handlers: {
            getJobArtifactsQuery: query,
          },
        });

        await waitForPromises();
      });

      it('refetches to clear empty jobs', () => {
        expect(query).toHaveBeenCalledTimes(2);
      });
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

  describe('navigation between pages', () => {
    const { pageInfo } = getJobArtifactsResponseThatPaginates.data.project.jobs;
    const query = jest.fn().mockResolvedValue(getJobArtifactsResponseThatPaginates);

    beforeEach(async () => {
      jest.spyOn(window.history, 'pushState');
      createComponent({
        handlers: {
          getJobArtifactsQuery: query,
        },
        data: { pageInfo },
      });

      await nextTick();
    });

    it.each`
      fromPage | toPage | expectedFirstPageSize | expectedLastPageSize | expectedPrevPageCursor  | expectedNextPageCursor
      ${1}     | ${2}   | ${JOBS_PER_PAGE}      | ${null}              | ${''}                   | ${pageInfo.endCursor}
      ${2}     | ${1}   | ${null}               | ${JOBS_PER_PAGE}     | ${pageInfo.startCursor} | ${undefined}
    `(
      'updates when going from page $fromPage to $toPage',
      async ({
        fromPage,
        toPage,
        expectedFirstPageSize,
        expectedLastPageSize,
        expectedPrevPageCursor,
        expectedNextPageCursor,
      }) => {
        findPagination().vm.$emit('input', fromPage);
        findPagination().vm.$emit('input', toPage);

        // pushes page change to browser history
        expect(window.history.pushState).toHaveBeenCalledWith(
          {},
          '',
          `http://test.host/?page=${toPage}`,
        );

        await waitForPromises();

        // updates artifact data  and page in pagination
        expect(findPagination().props('value')).toBe(toPage);
        expect(query).toHaveBeenLastCalledWith({
          projectPath: 'project/path',
          firstPageSize: expectedFirstPageSize,
          lastPageSize: expectedLastPageSize,
          prevPageCursor: expectedPrevPageCursor,
          nextPageCursor: expectedNextPageCursor,
        });
      },
    );

    it('starts on page from URL when provided', async () => {
      const currentpage = 2;
      await setPage(currentpage);

      setWindowLocation(`?page=${currentpage}`);

      expect(findPagination().props('value')).toEqual(2);
    });
  });

  describe('file type badges', () => {
    it('displays file type badge', async () => {
      createComponent();

      await waitForPromises();

      expect(findVisibleFileTypeBadge().text()).toBe('archive');
    });

    it('displays reamining file types in popover', async () => {
      createComponent();

      await waitForPromises();

      expect(findPopoverText().text()).toBe('+2 more');
      expect(findPopover().exists()).toBe(true);
      expect(findAllRemainingFileTypeBadges().at(0).text()).toBe('metadata');
      expect(findAllRemainingFileTypeBadges().at(1).text()).toBe('trace');
    });

    describe('with security file types', () => {
      const query = jest.fn().mockResolvedValue(jobArtifactsResponseWithSecurityFiles);

      beforeEach(async () => {
        createComponent({
          handlers: {
            getJobArtifactsQuery: query,
          },
        });

        await waitForPromises();
      });

      it('displays security badge first in the list', () => {
        expect(findVisibleFileTypeBadge().text()).toBe('sast');
      });
    });
  });
});
