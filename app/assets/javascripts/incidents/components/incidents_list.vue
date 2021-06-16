<script>
import {
  GlLoadingIcon,
  GlTable,
  GlAvatarsInline,
  GlAvatarLink,
  GlAvatar,
  GlTooltipDirective,
  GlButton,
  GlIcon,
  GlEmptyState,
} from '@gitlab/ui';
import { isValidSlaDueAt } from 'ee_else_ce/vue_shared/components/incidents/utils';
import { visitUrl, mergeUrlParams, joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { INCIDENT_SEVERITY } from '~/sidebar/components/severity/constants';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import Tracking from '~/tracking';
import {
  tdClass,
  thClass,
  bodyTrClass,
  initialPaginationState,
} from '~/vue_shared/components/paginated_table_with_search_and_tabs/constants';
import PaginatedTableWithSearchAndTabs from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  I18N,
  INCIDENT_STATUS_TABS,
  TH_CREATED_AT_TEST_ID,
  TH_INCIDENT_SLA_TEST_ID,
  TH_SEVERITY_TEST_ID,
  TH_PUBLISHED_TEST_ID,
  INCIDENT_DETAILS_PATH,
  trackIncidentCreateNewOptions,
  trackIncidentListViewsOptions,
} from '../constants';
import getIncidentsCountByStatus from '../graphql/queries/get_count_by_status.query.graphql';
import getIncidents from '../graphql/queries/get_incidents.query.graphql';

export default {
  trackIncidentCreateNewOptions,
  trackIncidentListViewsOptions,
  i18n: I18N,
  statusTabs: INCIDENT_STATUS_TABS,
  fields: [
    {
      key: 'severity',
      label: s__('IncidentManagement|Severity'),
      thClass: `${thClass} w-15p`,
      tdClass: `${tdClass} sortable-cell`,
      actualSortKey: 'SEVERITY',
      sortable: true,
      thAttr: TH_SEVERITY_TEST_ID,
    },
    {
      key: 'title',
      label: s__('IncidentManagement|Incident'),
      thClass: `gl-pointer-events-none`,
      tdClass,
    },
    {
      key: 'createdAt',
      label: s__('IncidentManagement|Date created'),
      thClass: `${thClass} gl-w-eighth`,
      tdClass: `${tdClass} sortable-cell`,
      actualSortKey: 'CREATED',
      sortable: true,
      thAttr: TH_CREATED_AT_TEST_ID,
    },
    {
      key: 'incidentSla',
      label: s__('IncidentManagement|Time to SLA'),
      thClass: `gl-text-right gl-w-eighth`,
      tdClass: `${tdClass} gl-text-right`,
      thAttr: TH_INCIDENT_SLA_TEST_ID,
      actualSortKey: 'SLA_DUE_AT',
      sortable: true,
      sortDirection: 'asc',
    },
    {
      key: 'assignees',
      label: s__('IncidentManagement|Assignees'),
      thClass: 'gl-pointer-events-none w-15p',
      tdClass,
    },
    {
      key: 'published',
      label: s__('IncidentManagement|Published'),
      thClass: `${thClass} w-15p`,
      tdClass: `${tdClass} sortable-cell`,
      actualSortKey: 'PUBLISHED',
      sortable: true,
      thAttr: TH_PUBLISHED_TEST_ID,
    },
  ],
  components: {
    GlLoadingIcon,
    GlTable,
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
    GlButton,
    TimeAgoTooltip,
    GlIcon,
    PublishedCell: () => import('ee_component/incidents/components/published_cell.vue'),
    ServiceLevelAgreementCell: () =>
      import('ee_component/vue_shared/components/incidents/service_level_agreement.vue'),
    GlEmptyState,
    SeverityToken,
    PaginatedTableWithSearchAndTabs,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'projectPath',
    'newIssuePath',
    'incidentTemplateName',
    'incidentType',
    'issuePath',
    'publishedAvailable',
    'emptyListSvgPath',
    'textQuery',
    'authorUsernameQuery',
    'assigneeUsernameQuery',
    'slaFeatureAvailable',
  ],
  apollo: {
    incidents: {
      query: getIncidents,
      variables() {
        return {
          searchTerm: this.searchTerm,
          authorUsername: this.authorUsername,
          assigneeUsername: this.assigneeUsername,
          projectPath: this.projectPath,
          status: this.statusFilter,
          issueTypes: ['INCIDENT'],
          sort: this.sort,
          firstPageSize: this.pagination.firstPageSize,
          lastPageSize: this.pagination.lastPageSize,
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
        };
      },
      update({ project: { issues: { nodes = [], pageInfo = {} } = {} } = {} }) {
        return {
          list: nodes,
          pageInfo,
        };
      },
      error() {
        this.errored = true;
      },
    },
    incidentsCount: {
      query: getIncidentsCountByStatus,
      variables() {
        return {
          searchTerm: this.searchTerm,
          authorUsername: this.authorUsername,
          assigneeUsername: this.assigneeUsername,
          projectPath: this.projectPath,
          issueTypes: ['INCIDENT'],
        };
      },
      update(data) {
        return data.project?.issueStatusCounts;
      },
    },
  },
  data() {
    return {
      errored: false,
      isErrorAlertDismissed: false,
      redirecting: false,
      incidents: {},
      incidentsCount: {},
      sort: 'CREATED_DESC',
      sortDesc: true,
      statusFilter: '',
      filteredByStatus: '',
      searchTerm: this.textQuery,
      authorUsername: this.authorUsernameQuery,
      assigneeUsername: this.assigneeUsernameQuery,
      pagination: initialPaginationState,
    };
  },
  computed: {
    showErrorMsg() {
      return this.errored && !this.isErrorAlertDismissed;
    },
    loading() {
      return this.$apollo.queries.incidents.loading;
    },
    isEmpty() {
      return !this.incidents?.list?.length;
    },
    showList() {
      return !this.isEmpty || this.errored || this.loading;
    },
    tbodyTrClass() {
      return {
        [bodyTrClass]: !this.loading && !this.isEmpty,
      };
    },
    newIncidentPath() {
      return mergeUrlParams(
        {
          issuable_template: this.incidentTemplateName,
          'issue[issue_type]': this.incidentType,
        },
        this.newIssuePath,
      );
    },
    availableFields() {
      const isHidden = {
        published: !this.publishedAvailable,
        incidentSla: !this.slaFeatureAvailable,
      };

      return this.$options.fields.filter(({ key }) => !isHidden[key]);
    },
    activeClosedTabHasNoIncidents() {
      const { all, closed } = this.incidentsCount || {};
      const isClosedTabActive = this.statusFilter === this.$options.statusTabs[1].filters;

      return isClosedTabActive && all && !closed;
    },
    emptyStateData() {
      const {
        emptyState: { title, emptyClosedTabTitle, description },
        createIncidentBtnLabel,
      } = this.$options.i18n;

      if (this.activeClosedTabHasNoIncidents) {
        return { title: emptyClosedTabTitle };
      }
      return {
        title,
        description,
        btnLink: this.newIncidentPath,
        btnText: createIncidentBtnLabel,
      };
    },
  },
  methods: {
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
    },
    navigateToIncidentDetails({ iid }) {
      return visitUrl(joinPaths(this.issuePath, INCIDENT_DETAILS_PATH, iid));
    },
    navigateToCreateNewIncident() {
      const { category, action } = this.$options.trackIncidentCreateNewOptions;
      Tracking.event(category, action);
      this.redirecting = true;
    },
    fetchSortedData({ sortBy, sortDesc }) {
      const field = this.availableFields.find(({ key }) => key === sortBy);
      const sortingDirection = sortDesc ? 'DESC' : 'ASC';

      this.pagination = initialPaginationState;

      // BootstapVue natively supports a `sortKey` parameter, but using it results in the sorting
      // icons not being updated properly in the header. We decided to fallback on `actualSortKey`
      // to bypass BootstrapVue's behavior until the bug is addressed upstream.
      // Related discussion: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60926/diffs#note_568020482
      // Upstream issue: https://github.com/bootstrap-vue/bootstrap-vue/issues/6602
      this.sort = `${field.actualSortKey}_${sortingDirection}`;
    },
    getSeverity(severity) {
      return INCIDENT_SEVERITY[severity];
    },
    pageChanged(pagination) {
      this.pagination = pagination;
    },
    statusChanged({ filters, status }) {
      this.statusFilter = filters;
      this.filteredByStatus = status;
    },
    filtersChanged({ searchTerm, authorUsername, assigneeUsername }) {
      this.searchTerm = searchTerm;
      this.authorUsername = authorUsername;
      this.assigneeUsername = assigneeUsername;
    },
    errorAlertDismissed() {
      this.isErrorAlertDismissed = true;
    },
    isValidSlaDueAt,
  },
};
</script>
<template>
  <div>
    <paginated-table-with-search-and-tabs
      :show-items="showList"
      :show-error-msg="showErrorMsg"
      :i18n="$options.i18n"
      :items="incidents.list || []"
      :page-info="incidents.pageInfo"
      :items-count="incidentsCount"
      :status-tabs="$options.statusTabs"
      :track-views-options="$options.trackIncidentListViewsOptions"
      filter-search-key="incidents"
      @page-changed="pageChanged"
      @tabs-changed="statusChanged"
      @filters-changed="filtersChanged"
      @error-alert-dismissed="errorAlertDismissed"
    >
      <template #header-actions>
        <gl-button
          v-if="!isEmpty || activeClosedTabHasNoIncidents"
          class="gl-my-3 gl-mr-5 create-incident-button"
          data-testid="createIncidentBtn"
          data-qa-selector="create_incident_button"
          :loading="redirecting"
          :disabled="redirecting"
          category="primary"
          variant="success"
          :href="newIncidentPath"
          @click="navigateToCreateNewIncident"
        >
          {{ $options.i18n.createIncidentBtnLabel }}
        </gl-button>
      </template>

      <template #title>
        {{ s__('IncidentManagement|Incidents') }}
      </template>

      <template #table>
        <gl-table
          :items="incidents.list || []"
          :fields="availableFields"
          :busy="loading"
          stacked="md"
          :tbody-tr-class="tbodyTrClass"
          sort-direction="desc"
          :sort-desc.sync="sortDesc"
          sort-by="createdAt"
          show-empty
          no-local-sorting
          sort-icon-left
          fixed
          @row-clicked="navigateToIncidentDetails"
          @sort-changed="fetchSortedData"
        >
          <template #cell(severity)="{ item }">
            <severity-token :severity="getSeverity(item.severity)" />
          </template>

          <template #cell(title)="{ item }">
            <div :class="{ 'gl-display-flex gl-align-items-center': item.state === 'closed' }">
              <div class="gl-max-w-full text-truncate" :title="item.title">{{ item.title }}</div>
              <gl-icon
                v-if="item.state === 'closed'"
                name="issue-close"
                class="gl-mx-1 gl-fill-blue-500 gl-flex-shrink-0"
                :size="16"
                data-testid="incident-closed"
              />
            </div>
          </template>

          <template #cell(createdAt)="{ item }">
            <time-ago-tooltip :time="item.createdAt" />
          </template>

          <template v-if="slaFeatureAvailable" #cell(incidentSla)="{ item }">
            <service-level-agreement-cell
              v-if="isValidSlaDueAt(item.slaDueAt)"
              :issue-iid="item.iid"
              :project-path="projectPath"
              :sla-due-at="item.slaDueAt"
              data-testid="incident-sla"
            />
          </template>

          <template #cell(assignees)="{ item }">
            <div data-testid="incident-assignees">
              <template v-if="hasAssignees(item.assignees)">
                <gl-avatars-inline
                  :avatars="item.assignees.nodes"
                  :collapsed="true"
                  :max-visible="4"
                  :avatar-size="24"
                  badge-tooltip-prop="name"
                  :badge-tooltip-max-chars="100"
                >
                  <template #avatar="{ avatar }">
                    <gl-avatar-link
                      :key="avatar.username"
                      v-gl-tooltip
                      target="_blank"
                      :href="avatar.webUrl"
                      :title="avatar.name"
                    >
                      <gl-avatar :src="avatar.avatarUrl" :label="avatar.name" :size="24" />
                    </gl-avatar-link>
                  </template>
                </gl-avatars-inline>
              </template>
              <template v-else>
                {{ $options.i18n.unassigned }}
              </template>
            </div>
          </template>

          <template v-if="publishedAvailable" #cell(published)="{ item }">
            <published-cell
              :status-page-published-incident="item.statusPagePublishedIncident"
              :un-published="$options.i18n.unPublished"
            />
          </template>
          <template #table-busy>
            <gl-loading-icon size="lg" color="dark" class="mt-3" />
          </template>

          <template v-if="errored" #empty>
            {{ $options.i18n.noIncidents }}
          </template>
        </gl-table>
      </template>
      <template #empty-state>
        <gl-empty-state
          :title="emptyStateData.title"
          :svg-path="emptyListSvgPath"
          :description="emptyStateData.description"
          :primary-button-link="emptyStateData.btnLink"
          :primary-button-text="emptyStateData.btnText"
        />
      </template>
    </paginated-table-with-search-and-tabs>
  </div>
</template>
