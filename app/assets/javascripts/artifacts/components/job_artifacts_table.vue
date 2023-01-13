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
} from '@gitlab/ui';
import { createAlert } from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import { totalArtifactsSizeForJob, mapArchivesToJobNodes, mapBooleansToJobNodes } from '../utils';
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
} from '../constants';
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
    CiIcon,
    TimeAgo,
    ArtifactsTableRowDetails,
    FeedbackBanner,
  },
  inject: ['projectPath', 'canDestroyArtifacts'],
  apollo: {
    jobArtifacts: {
      query: getJobArtifactsQuery,
      variables() {
        return this.queryVariables;
      },
      update({ project: { jobs: { nodes = [], pageInfo = {}, count = 0 } = {} } }) {
        this.pageInfo = pageInfo;
        this.count = count;
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
      count: 0,
      pageInfo: {},
      expandedJobs: [],
      pagination: INITIAL_PAGINATION_STATE,
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
      return this.count > JOBS_PER_PAGE;
    },
    prevPage() {
      return Number(this.pageInfo.hasPreviousPage);
    },
    nextPage() {
      return Number(this.pageInfo.hasNextPage);
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
    downloadPath(job) {
      return job.archive?.downloadPath;
    },
    downloadButtonDisabled(job) {
      return !job.archive?.downloadPath;
    },
    browseButtonDisabled(job) {
      return !job.browseArtifactsPath;
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
    <gl-table
      :items="jobArtifacts"
      :fields="$options.fields"
      :busy="$apollo.queries.jobArtifacts.loading"
      stacked="sm"
      details-td-class="gl-bg-gray-10! gl-p-0! gl-overflow-auto"
    >
      <template #table-busy>
        <gl-loading-icon size="lg" />
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
            :title="$options.i18n.delete"
            :aria-label="$options.i18n.delete"
            data-testid="job-artifacts-delete-button"
            disabled
          />
        </gl-button-group>
      </template>
      <template #row-details="{ item: { artifacts } }">
        <artifacts-table-row-details
          :artifacts="artifacts"
          :query-variables="queryVariables"
          @refetch="refetchArtifacts"
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
