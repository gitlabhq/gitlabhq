<script>
import {
  GlLoadingIcon,
  GlTable,
  GlLink,
  GlButtonGroup,
  GlButton,
  GlBadge,
  GlIcon,
  GlPagination,
  GlFormCheckbox,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import { totalArtifactsSizeForJob, mapArchivesToJobNodes, mapBooleansToJobNodes } from '../utils';
import bulkDestroyJobArtifactsMutation from '../graphql/mutations/bulk_destroy_job_artifacts.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import {
  STATUS_BADGE_VARIANTS,
  I18N_DOWNLOAD,
  I18N_BROWSE,
  I18N_DELETE,
  I18N_EXPIRED,
  I18N_DESTROY_ERROR,
  I18N_FETCH_ERROR,
  I18N_ARTIFACTS,
  I18N_JOB,
  I18N_SIZE,
  I18N_CREATED,
  I18N_ARTIFACTS_COUNT,
  INITIAL_CURRENT_PAGE,
  INITIAL_PREVIOUS_PAGE_CURSOR,
  INITIAL_NEXT_PAGE_CURSOR,
  JOBS_PER_PAGE,
  INITIAL_LAST_PAGE_SIZE,
  BULK_DELETE_FEATURE_FLAG,
  I18N_BULK_DELETE_ERROR,
  I18N_BULK_DELETE_PARTIAL_ERROR,
  I18N_BULK_DELETE_CONFIRMATION_TOAST,
  SELECTED_ARTIFACTS_MAX_COUNT,
} from '../constants';
import JobCheckbox from './job_checkbox.vue';
import ArtifactsBulkDelete from './artifacts_bulk_delete.vue';
import BulkDeleteModal from './bulk_delete_modal.vue';
import ArtifactsTableRowDetails from './artifacts_table_row_details.vue';
import FeedbackBanner from './feedback_banner.vue';

const INITIAL_PAGINATION_STATE = {
  currentPage: INITIAL_CURRENT_PAGE,
  prevPageCursor: INITIAL_PREVIOUS_PAGE_CURSOR,
  nextPageCursor: INITIAL_NEXT_PAGE_CURSOR,
  firstPageSize: JOBS_PER_PAGE,
  lastPageSize: INITIAL_LAST_PAGE_SIZE,
};

export default {
  name: 'JobArtifactsTable',
  components: {
    GlLoadingIcon,
    GlTable,
    GlLink,
    GlButtonGroup,
    GlButton,
    GlBadge,
    GlIcon,
    GlPagination,
    GlFormCheckbox,
    CiIcon,
    TimeAgo,
    JobCheckbox,
    ArtifactsBulkDelete,
    BulkDeleteModal,
    ArtifactsTableRowDetails,
    FeedbackBanner,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectId', 'projectPath', 'canDestroyArtifacts'],
  apollo: {
    jobArtifacts: {
      query: getJobArtifactsQuery,
      variables() {
        return this.queryVariables;
      },
      update({ project: { jobs: { nodes = [], pageInfo = {} } = {} } }) {
        this.pageInfo = pageInfo;
        return nodes
          .map(mapArchivesToJobNodes)
          .map(mapBooleansToJobNodes)
          .map((jobNode) => {
            return {
              ...jobNode,
              // GlTable uses an item's _showDetails attribute to determine whether
              // it should show the <template #row-details /> for its table row
              _showDetails: this.expandedJobs.includes(jobNode.id),
            };
          });
      },
      error() {
        createAlert({
          message: I18N_FETCH_ERROR,
        });
      },
    },
  },
  data() {
    return {
      jobArtifacts: [],
      pageInfo: {},
      expandedJobs: [],
      selectedArtifacts: [],
      pagination: INITIAL_PAGINATION_STATE,
      isBulkDeleteModalVisible: false,
      jobArtifactsToDelete: [],
      isBulkDeleting: false,
    };
  },
  computed: {
    queryVariables() {
      return {
        projectPath: this.projectPath,
        firstPageSize: this.pagination.firstPageSize,
        lastPageSize: this.pagination.lastPageSize,
        prevPageCursor: this.pagination.prevPageCursor,
        nextPageCursor: this.pagination.nextPageCursor,
      };
    },
    showPagination() {
      const { hasNextPage, hasPreviousPage } = this.pageInfo;

      return hasNextPage || hasPreviousPage;
    },
    prevPage() {
      return Number(this.pageInfo.hasPreviousPage);
    },
    nextPage() {
      return Number(this.pageInfo.hasNextPage);
    },
    fields() {
      return [
        this.canBulkDestroyArtifacts && {
          key: 'checkbox',
          label: '',
        },
        ...this.$options.fields,
      ];
    },
    anyArtifactsSelected() {
      return Boolean(this.selectedArtifacts.length);
    },
    isSelectedArtifactsLimitReached() {
      return this.selectedArtifacts.length >= SELECTED_ARTIFACTS_MAX_COUNT;
    },
    canBulkDestroyArtifacts() {
      return this.glFeatures[BULK_DELETE_FEATURE_FLAG] && this.canDestroyArtifacts;
    },
    isDeletingArtifactsForJob() {
      return this.jobArtifactsToDelete.length > 0;
    },
    artifactsToDelete() {
      return this.isDeletingArtifactsForJob ? this.jobArtifactsToDelete : this.selectedArtifacts;
    },
  },
  methods: {
    refetchArtifacts() {
      this.$apollo.queries.jobArtifacts.refetch();
    },
    artifactsSize(item) {
      return totalArtifactsSizeForJob(item);
    },
    pipelineId(item) {
      const id = getIdFromGraphQLId(item.pipeline.id);
      return `#${id}`;
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.pageInfo;

      if (page > this.pagination.currentPage) {
        this.pagination = {
          ...INITIAL_PAGINATION_STATE,
          nextPageCursor: endCursor,
          currentPage: page,
        };
      } else {
        this.pagination = {
          lastPageSize: JOBS_PER_PAGE,
          firstPageSize: null,
          prevPageCursor: startCursor,
          currentPage: page,
        };
      }
    },
    handleRowToggle(toggleDetails, hasArtifacts, id, detailsShowing) {
      if (!hasArtifacts) return;
      toggleDetails();

      if (!detailsShowing) {
        this.expandedJobs.push(id);
      } else {
        this.expandedJobs.splice(this.expandedJobs.indexOf(id), 1);
      }
    },
    selectArtifact(artifactNode, checked) {
      if (checked) {
        if (!this.isSelectedArtifactsLimitReached) {
          this.selectedArtifacts.push(artifactNode.id);
        }
      } else {
        this.selectedArtifacts.splice(this.selectedArtifacts.indexOf(artifactNode.id), 1);
      }
    },
    onConfirmBulkDelete(e) {
      // don't close modal until deletion is complete
      if (e) {
        e.preventDefault();
      }
      this.isBulkDeleting = true;

      this.$apollo
        .mutate({
          mutation: bulkDestroyJobArtifactsMutation,
          variables: {
            projectId: convertToGraphQLId(TYPENAME_PROJECT, this.projectId),
            ids: this.artifactsToDelete,
          },
          update: (store, { data }) => {
            const { errors, destroyedCount, destroyedIds } = data.bulkDestroyJobArtifacts;
            if (errors?.length) {
              createAlert({
                message: I18N_BULK_DELETE_PARTIAL_ERROR,
                captureError: true,
                error: new Error(errors.join(' ')),
              });
            }
            if (destroyedIds?.length) {
              this.$toast.show(I18N_BULK_DELETE_CONFIRMATION_TOAST(destroyedCount));

              // Remove deleted artifacts from the cache
              destroyedIds.forEach((id) => {
                removeArtifactFromStore(store, id, getJobArtifactsQuery, this.queryVariables);
              });
              store.gc();

              if (!this.isDeletingArtifactsForJob) {
                this.clearSelectedArtifacts();
              }
            }
          },
        })
        .catch((error) => {
          this.onError(error);
        })
        .finally(() => {
          this.isBulkDeleting = false;
          this.isBulkDeleteModalVisible = false;
          this.jobArtifactsToDelete = [];
        });
    },
    onError(error) {
      createAlert({
        message: I18N_BULK_DELETE_ERROR,
        captureError: true,
        error,
      });
    },
    handleBulkDeleteModalShow() {
      this.isBulkDeleteModalVisible = true;
    },
    handleBulkDeleteModalHidden() {
      this.isBulkDeleteModalVisible = false;
      this.jobArtifactsToDelete = [];
    },
    clearSelectedArtifacts() {
      this.selectedArtifacts = [];
    },
    downloadPath(job) {
      return job.archive?.downloadPath;
    },
    downloadButtonDisabled(job) {
      return !job.archive?.downloadPath;
    },
    browseButtonDisabled(job) {
      return !job.browseArtifactsPath;
    },
    deleteButtonDisabled(job) {
      return !job.hasArtifacts || !this.canBulkDestroyArtifacts;
    },
    deleteArtifactsForJob(job) {
      this.jobArtifactsToDelete = job.artifacts.nodes.map((node) => node.id);
      this.handleBulkDeleteModalShow();
    },
  },
  fields: [
    {
      key: 'artifacts',
      label: I18N_ARTIFACTS,
      thClass: 'gl-w-quarter',
    },
    {
      key: 'job',
      label: I18N_JOB,
      thClass: 'gl-w-35p',
    },
    {
      key: 'size',
      label: I18N_SIZE,
      thClass: 'gl-w-15p gl-text-right',
      tdClass: 'gl-text-right',
    },
    {
      key: 'created',
      label: I18N_CREATED,
      thClass: 'gl-w-eighth gl-text-center',
      tdClass: 'gl-text-center',
    },
    {
      key: 'actions',
      label: '',
      thClass: 'gl-w-eighth',
      tdClass: 'gl-text-right',
    },
  ],
  STATUS_BADGE_VARIANTS,
  i18n: {
    download: I18N_DOWNLOAD,
    browse: I18N_BROWSE,
    delete: I18N_DELETE,
    expired: I18N_EXPIRED,
    destroyArtifactError: I18N_DESTROY_ERROR,
    fetchArtifactsError: I18N_FETCH_ERROR,
    artifactsLabel: I18N_ARTIFACTS,
    jobLabel: I18N_JOB,
    sizeLabel: I18N_SIZE,
    createdLabel: I18N_CREATED,
    artifactsCount: I18N_ARTIFACTS_COUNT,
  },
};
</script>
<template>
  <div>
    <feedback-banner />
    <artifacts-bulk-delete
      v-if="canBulkDestroyArtifacts"
      :selected-artifacts="selectedArtifacts"
      :is-selected-artifacts-limit-reached="isSelectedArtifactsLimitReached"
      @clearSelectedArtifacts="clearSelectedArtifacts"
      @showBulkDeleteModal="handleBulkDeleteModalShow"
    />
    <bulk-delete-modal
      :visible="isBulkDeleteModalVisible"
      :artifacts-to-delete="artifactsToDelete"
      :is-deleting="isBulkDeleting"
      @primary="onConfirmBulkDelete"
      @hidden="handleBulkDeleteModalHidden"
    />
    <gl-table
      :items="jobArtifacts"
      :fields="fields"
      :busy="$apollo.queries.jobArtifacts.loading"
      stacked="sm"
      details-td-class="gl-bg-gray-10! gl-p-0! gl-overflow-auto"
    >
      <template #table-busy>
        <gl-loading-icon size="lg" />
      </template>
      <template v-if="canBulkDestroyArtifacts" #head(checkbox)>
        <gl-form-checkbox
          :disabled="!anyArtifactsSelected"
          :checked="anyArtifactsSelected"
          :indeterminate="anyArtifactsSelected"
          @change="clearSelectedArtifacts"
        />
      </template>
      <template
        v-if="canBulkDestroyArtifacts"
        #cell(checkbox)="{ item: { hasArtifacts, artifacts } }"
      >
        <job-checkbox
          :has-artifacts="hasArtifacts"
          :selected-artifacts="
            artifacts.nodes.filter((node) => selectedArtifacts.includes(node.id))
          "
          :unselected-artifacts="
            artifacts.nodes.filter((node) => !selectedArtifacts.includes(node.id))
          "
          :is-selected-artifacts-limit-reached="isSelectedArtifactsLimitReached"
          @selectArtifact="selectArtifact"
        />
      </template>
      <template
        #cell(artifacts)="{ item: { id, artifacts, hasArtifacts }, toggleDetails, detailsShowing }"
      >
        <span
          :class="{ 'gl-cursor-pointer': hasArtifacts }"
          data-testid="job-artifacts-count"
          @click="handleRowToggle(toggleDetails, hasArtifacts, id, detailsShowing)"
        >
          <gl-icon
            v-if="hasArtifacts"
            :name="detailsShowing ? 'chevron-down' : 'chevron-right'"
            class="gl-mr-2"
          />
          <strong>
            {{ $options.i18n.artifactsCount(artifacts.nodes.length) }}
          </strong>
        </span>
      </template>
      <template #cell(job)="{ item }">
        <span class="gl-display-inline-flex gl-align-items-center gl-w-full gl-mb-4">
          <span data-testid="job-artifacts-job-status">
            <ci-icon v-if="item.succeeded" :status="item.detailedStatus" class="gl-mr-3" />
            <gl-badge
              v-else
              :icon="item.detailedStatus.icon"
              :variant="$options.STATUS_BADGE_VARIANTS[item.detailedStatus.group]"
              class="gl-mr-3"
            >
              {{ item.detailedStatus.label }}
            </gl-badge>
          </span>
          <gl-link :href="item.webPath" class="gl-font-weight-bold">
            {{ item.name }}
          </gl-link>
        </span>
        <span class="gl-display-inline-flex">
          <gl-icon name="pipeline" class="gl-mr-2" />
          <gl-link
            :href="item.pipeline.path"
            class="gl-text-black-normal gl-text-decoration-underline gl-mr-4"
          >
            {{ pipelineId(item) }}
          </gl-link>
          <gl-icon name="branch" class="gl-mr-2" />
          <gl-link
            :href="item.refPath"
            class="gl-text-black-normal gl-text-decoration-underline gl-mr-4"
          >
            {{ item.refName }}
          </gl-link>
          <gl-icon name="commit" class="gl-mr-2" />
          <gl-link
            :href="item.commitPath"
            class="gl-text-black-normal gl-text-decoration-underline gl-mr-4"
          >
            {{ item.shortSha }}
          </gl-link>
        </span>
      </template>
      <template #cell(size)="{ item }">
        <span data-testid="job-artifacts-size">{{ artifactsSize(item) }}</span>
      </template>
      <template #cell(created)="{ item }">
        <time-ago data-testid="job-artifacts-created" :time="item.finishedAt" />
      </template>
      <template #cell(actions)="{ item }">
        <gl-button-group>
          <gl-button
            icon="download"
            :disabled="downloadButtonDisabled(item)"
            :href="downloadPath(item)"
            :title="$options.i18n.download"
            :aria-label="$options.i18n.download"
            data-testid="job-artifacts-download-button"
          />
          <gl-button
            icon="folder-open"
            :disabled="browseButtonDisabled(item)"
            :href="item.browseArtifactsPath"
            :title="$options.i18n.browse"
            :aria-label="$options.i18n.browse"
            data-testid="job-artifacts-browse-button"
          />
          <gl-button
            v-if="canDestroyArtifacts"
            icon="remove"
            :disabled="deleteButtonDisabled(item)"
            :title="$options.i18n.delete"
            :aria-label="$options.i18n.delete"
            data-testid="job-artifacts-delete-button"
            @click="deleteArtifactsForJob(item)"
          />
        </gl-button-group>
      </template>
      <template #row-details="{ item: { artifacts } }">
        <artifacts-table-row-details
          :artifacts="artifacts"
          :selected-artifacts="selectedArtifacts"
          :query-variables="queryVariables"
          :is-selected-artifacts-limit-reached="isSelectedArtifactsLimitReached"
          @refetch="refetchArtifacts"
          @selectArtifact="selectArtifact"
        />
      </template>
    </gl-table>
    <gl-pagination
      v-if="showPagination"
      :value="pagination.currentPage"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-mt-3"
      @input="handlePageChange"
    />
  </div>
</template>
