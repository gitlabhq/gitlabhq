<script>
import {
  GlBadge,
  GlSkeletonLoader,
  GlTable,
  GlLink,
  GlButtonGroup,
  GlButton,
  GlIcon,
  GlPagination,
  GlPopover,
  GlFormCheckbox,
  GlTooltipDirective,
} from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { s__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { updateHistory, getParameterByName, setUrlParams } from '~/lib/utils/url_utility';
import { scrollToElement } from '~/lib/utils/common_utils';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import { totalArtifactsSizeForJob, mapArchivesToJobNodes, mapBooleansToJobNodes } from '../utils';
import bulkDestroyJobArtifactsMutation from '../graphql/mutations/bulk_destroy_job_artifacts.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import {
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
  I18N_BULK_DELETE_ERROR,
  I18N_BULK_DELETE_PARTIAL_ERROR,
  I18N_BULK_DELETE_CONFIRMATION_TOAST,
  I18N_BULK_DELETE_MAX_SELECTED,
  I18N_CHECKBOX,
} from '../constants';
import JobCheckbox from './job_checkbox.vue';
import ArtifactsBulkDelete from './artifacts_bulk_delete.vue';
import BulkDeleteModal from './bulk_delete_modal.vue';
import ArtifactsTableRowDetails from './artifacts_table_row_details.vue';

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
    GlBadge,
    GlSkeletonLoader,
    GlTable,
    GlLink,
    GlButtonGroup,
    GlButton,
    GlIcon,
    GlPagination,
    GlPopover,
    GlFormCheckbox,
    TimeAgo,
    CiIcon,
    JobCheckbox,
    ArtifactsBulkDelete,
    BulkDeleteModal,
    ArtifactsTableRowDetails,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectId', 'projectPath', 'canDestroyArtifacts', 'jobArtifactsCountLimit'],
  apollo: {
    jobArtifacts: {
      query: getJobArtifactsQuery,
      variables() {
        return this.queryVariables;
      },
      update({ project: { jobs: { nodes = [], pageInfo = {} } = {} } }) {
        this.pageInfo = pageInfo;

        const jobNodes = nodes
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

        if (jobNodes.some((jobNode) => !jobNode.hasArtifacts)) {
          this.$apollo.queries.jobArtifacts.refetch();
        }

        return jobNodes;
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
      page: INITIAL_CURRENT_PAGE,
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
      if (this.canBulkDestroyArtifacts) {
        return [
          {
            key: 'checkbox',
            label: I18N_CHECKBOX,
            thClass: 'gl-w-1/20',
          },
          ...this.$options.fields,
        ];
      }

      return this.$options.fields;
    },
    anyArtifactsSelected() {
      return Boolean(this.selectedArtifacts.length);
    },
    isSelectedArtifactsLimitReached() {
      return this.selectedArtifacts.length >= this.jobArtifactsCountLimit;
    },
    canBulkDestroyArtifacts() {
      return this.canDestroyArtifacts;
    },
    isDeletingArtifactsForJob() {
      return this.jobArtifactsToDelete.length > 0;
    },
    artifactsToDelete() {
      return this.isDeletingArtifactsForJob ? this.jobArtifactsToDelete : this.selectedArtifacts;
    },
    isAnyVisibleArtifactSelected() {
      return this.jobArtifacts.some((job) =>
        job.artifacts.nodes.some((artifactNode) =>
          this.selectedArtifacts.includes(artifactNode.id),
        ),
      );
    },
    areAllVisibleArtifactsSelected() {
      return this.jobArtifacts.every((job) =>
        job.artifacts.nodes.every((artifactNode) =>
          this.selectedArtifacts.includes(artifactNode.id),
        ),
      );
    },
    selectAllTooltipText() {
      return this.isSelectedArtifactsLimitReached && !this.isAnyVisibleArtifactSelected
        ? I18N_BULK_DELETE_MAX_SELECTED
        : '';
    },
  },
  created() {
    this.updateQueryParamsFromUrl();
    window.addEventListener('popstate', this.updateQueryParamsFromUrl);
  },
  destroyed() {
    window.removeEventListener('popstate', this.updateQueryParamsFromUrl);
  },
  methods: {
    updateQueryParamsFromUrl() {
      this.page = Number(getParameterByName('page')) || INITIAL_CURRENT_PAGE;
    },
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
      this.page = page;

      updateHistory({
        url: setUrlParams({ page }),
      });
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

      scrollToElement(this.$el);
    },
    // eslint-disable-next-line max-params
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
      const isSelected = this.selectedArtifacts.includes(artifactNode.id);

      if (checked && !isSelected && !this.isSelectedArtifactsLimitReached) {
        this.selectedArtifacts.push(artifactNode.id);
      } else if (isSelected) {
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
    handleSelectAllChecked(checked) {
      this.jobArtifacts.map((job) =>
        job.artifacts.nodes.map((artifactNode) => this.selectArtifact(artifactNode, checked)),
      );
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
      return !job.browseArtifactsPath || !job.hasMetadata;
    },
    browseButtonHref(job) {
      // make href blank when button is disabled so `cursor: not-allowed` is applied
      if (this.browseButtonDisabled(job)) return '';

      return job.browseArtifactsPath;
    },
    deleteButtonDisabled(job) {
      return !job.hasArtifacts || !this.canBulkDestroyArtifacts;
    },
    deleteArtifactsForJob(job) {
      this.jobArtifactsToDelete = job.artifacts.nodes.map((node) => node.id);
      this.handleBulkDeleteModalShow();
    },
    artifactBadges(artifacts = []) {
      if (!artifacts.length) {
        return { first: null, remaining: [] };
      }

      // Extract file types and normalize to lowercase
      const fileTypeList = artifacts.map((artifact) => artifact.fileType?.toLowerCase() || '');

      // Find the first security file type (sast/dast)
      const securityFileType = fileTypeList.find(
        (fileType) => fileType === 'sast' || fileType === 'dast',
      );

      if (securityFileType) {
        const index = fileTypeList.findIndex((fileType) => fileType === securityFileType);
        // Move security file type to the front of the array
        fileTypeList.unshift(fileTypeList.splice(index, 1)[0]);
      }

      return {
        first: fileTypeList.shift(),
        remaining: fileTypeList,
      };
    },
    popoverText(remaining = []) {
      return sprintf(s__('Artifacts|+%{count} more'), {
        count: remaining.length,
      });
    },
    popoverTarget(id) {
      return `artifact-popover-${id}`;
    },
  },
  fields: [
    {
      key: 'artifacts',
      label: I18N_ARTIFACTS,
      thClass: 'gl-w-1/8',
    },
    {
      key: 'job',
      label: I18N_JOB,
      thClass: 'gl-w-7/20',
    },
    {
      key: 'size',
      label: I18N_SIZE,
      thAlignRight: true,
      thClass: 'gl-w-3/20',
      tdClass: 'gl-text-right',
    },
    {
      key: 'created',
      label: I18N_CREATED,
      thClass: 'gl-w-1/8 gl-text-center',
      tdClass: 'gl-text-center',
    },
    {
      key: 'actions',
      label: '',
      thClass: 'gl-w-4/20',
      tdClass: 'gl-text-right',
    },
  ],
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
  TBODY_TR_ATTR: {
    'data-testid': 'job-artifact-table-row',
  },
};
</script>
<template>
  <div>
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
      details-td-class="!gl-bg-subtle !gl-p-0 gl-overflow-auto"
      :tbody-tr-attr="$options.TBODY_TR_ATTR"
    >
      <template #table-busy>
        <gl-skeleton-loader v-for="i in 20" :key="i" :width="1000" :height="75">
          <rect width="90" height="20" x="40" y="5" rx="4" />
          <rect width="300" height="40" x="180" y="5" rx="4" />
          <rect width="80" height="20" x="610" y="5" rx="4" />
          <rect width="80" height="20" x="710" y="5" rx="4" />
          <rect width="100" height="30" x="900" y="5" rx="4" />
        </gl-skeleton-loader>
      </template>

      <template v-if="canBulkDestroyArtifacts" #head(checkbox)>
        <gl-form-checkbox
          v-gl-tooltip.right
          :title="selectAllTooltipText"
          :checked="isAnyVisibleArtifactSelected"
          :indeterminate="isAnyVisibleArtifactSelected && !areAllVisibleArtifactsSelected"
          :disabled="isSelectedArtifactsLimitReached && !isAnyVisibleArtifactSelected"
          data-testid="select-all-artifacts-checkbox"
          @change="handleSelectAllChecked"
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
        <div class="gl-mb-3 gl-inline-flex gl-items-center gl-gap-3">
          <span data-testid="job-artifacts-job-status">
            <ci-icon :status="item.detailedStatus" />
          </span>
          <gl-link :href="item.webPath">
            {{ item.name }}
          </gl-link>
          <template v-if="artifactBadges(item.artifacts.nodes)">
            <gl-badge data-testid="visible-file-type-badge">
              {{ artifactBadges(item.artifacts.nodes).first }}
            </gl-badge>
            <template v-if="artifactBadges(item.artifacts.nodes).remaining.length">
              <gl-badge :id="popoverTarget(item.id)" data-testid="file-types-popover-text">
                {{ popoverText(artifactBadges(item.artifacts.nodes).remaining) }}
              </gl-badge>
              <gl-popover :target="popoverTarget(item.id)" placement="right" triggers="hover focus">
                <div class="gl-flex gl-flex-wrap gl-gap-3">
                  <gl-badge
                    v-for="(fileType, index) in artifactBadges(item.artifacts.nodes).remaining"
                    :key="index"
                    data-testid="remaining-file-type-badges"
                  >
                    {{ fileType }}
                  </gl-badge>
                </div>
              </gl-popover>
            </template>
          </template>
        </div>
        <div class="gl-mb-1">
          <gl-icon name="pipeline" class="gl-mr-2" />
          <gl-link :href="item.pipeline.path" class="gl-mr-2">
            {{ pipelineId(item) }}
          </gl-link>
          <span class="gl-inline-block gl-rounded-base gl-bg-strong gl-px-2">
            <gl-icon name="commit" :size="12" class="gl-mr-2" />
            <gl-link :href="item.commitPath" class="gl-text-sm gl-text-default gl-font-monospace">
              {{ item.shortSha }}
            </gl-link>
          </span>
        </div>
        <div>
          <span class="gl-inline-block gl-rounded-base gl-bg-strong gl-px-2">
            <gl-icon name="branch" :size="12" class="gl-mr-1" />
            <gl-link :href="item.refPath" class="gl-text-sm gl-text-default gl-font-monospace">
              {{ item.refName }}
            </gl-link>
          </span>
        </div>
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
            :href="browseButtonHref(item)"
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
      class="gl-mt-6"
      @input="handlePageChange"
    />
  </div>
</template>
