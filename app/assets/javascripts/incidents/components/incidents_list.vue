<script>
import {
  GlLink,
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
import { STATUS_CLOSED } from '~/issues/constants';
import { visitUrl, mergeUrlParams, joinPaths } from '~/lib/utils/url_utility';
import { isValidDateString } from '~/lib/utils/datetime_utility';
import { s__, n__ } from '~/locale';
import { INCIDENT_SEVERITY } from '~/sidebar/constants';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import Tracking from '~/tracking';
import {
  tdClass,
  bodyTrClass,
  initialPaginationState,
} from '~/vue_shared/components/paginated_table_with_search_and_tabs/constants';
import PaginatedTableWithSearchAndTabs from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import {
  I18N,
  INCIDENT_STATUS_TABS,
  ESCALATION_STATUSES,
  TH_CREATED_AT_TEST_ID,
  TH_INCIDENT_SLA_TEST_ID,
  TH_SEVERITY_TEST_ID,
  TH_ESCALATION_STATUS_TEST_ID,
  TH_PUBLISHED_TEST_ID,
  INCIDENT_DETAILS_PATH,
  trackIncidentCreateNewOptions,
  trackIncidentListViewsOptions,
} from '../constants';
import getIncidentsCountByStatus from '../graphql/queries/get_count_by_status.query.graphql';
import getIncidents from '../graphql/queries/get_incidents.query.graphql';

const MAX_VISIBLE_ASSIGNEES = 3;

export default {
  trackIncidentCreateNewOptions,
  trackIncidentListViewsOptions,
  i18n: I18N,
  statusTabs: INCIDENT_STATUS_TABS,
  fields: [
    {
      key: 'severity',
      label: s__('IncidentManagement|Severity'),
      variant: 'secondary',
      thClass: `gl-w-3/20`,
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
      key: 'escalationStatus',
      label: s__('IncidentManagement|Status'),
      variant: 'secondary',
      thClass: `gl-w-1/8`,
      tdClass: `${tdClass} sortable-cell`,
      actualSortKey: 'ESCALATION_STATUS',
      sortable: true,
      thAttr: TH_ESCALATION_STATUS_TEST_ID,
    },
    {
      key: 'createdAt',
      label: s__('IncidentManagement|Date created'),
      variant: 'secondary',
      thClass: `gl-w-1/8`,
      tdClass: `${tdClass} sortable-cell`,
      actualSortKey: 'CREATED',
      sortable: true,
      thAttr: TH_CREATED_AT_TEST_ID,
    },
    {
      key: 'incidentSla',
      label: s__('IncidentManagement|Time to SLA'),
      variant: 'secondary',
      thAlignRight: true,
      thClass: `gl-w-2/20`,
      tdClass: `${tdClass} gl-text-right`,
      thAttr: TH_INCIDENT_SLA_TEST_ID,
      actualSortKey: 'SLA_DUE_AT',
      sortable: true,
    },
    {
      key: 'assignees',
      label: s__('IncidentManagement|Assignees'),
      thClass: 'gl-pointer-events-none gl-w-3/20',
      tdClass,
    },
    {
      key: 'published',
      label: s__('IncidentManagement|Published'),
      variant: 'secondary',
      thClass: `gl-w-15`,
      tdClass: `${tdClass} sortable-cell`,
      actualSortKey: 'PUBLISHED',
      sortable: true,
      thAttr: TH_PUBLISHED_TEST_ID,
    },
  ],
  MAX_VISIBLE_ASSIGNEES,
  components: {
    GlLink,
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
    TooltipOnTruncate,
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
    'canCreateIncident',
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
        emptyState: { title, emptyClosedTabTitle, description, cannotCreateIncidentDescription },
        createIncidentBtnLabel,
      } = this.$options.i18n;

      if (this.activeClosedTabHasNoIncidents) {
        return { title: emptyClosedTabTitle };
      }
      if (!this.canCreateIncident) {
        return { title, description: cannotCreateIncidentDescription };
      }
      return {
        title,
        description,
        btnLink: this.newIncidentPath,
        btnText: createIncidentBtnLabel,
      };
    },
    isHeaderButtonVisible() {
      return this.canCreateIncident && (!this.isEmpty || this.activeClosedTabHasNoIncidents);
    },
  },
  methods: {
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
    },
    navigateToIncidentDetails({ iid }) {
      return visitUrl(this.showIncidentLink({ iid }));
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
    getEscalationStatus(escalationStatus) {
      return ESCALATION_STATUSES[escalationStatus] || this.$options.i18n.noEscalationStatus;
    },
    isClosed(item) {
      return item.state === STATUS_CLOSED;
    },
    showIncidentLink({ iid }) {
      return joinPaths(this.issuePath, INCIDENT_DETAILS_PATH, iid);
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
    assigneesBadgeSrOnlyText(item) {
      return n__(
        '%d additional assignee',
        '%d additional assignees',
        item.assignees.nodes.length - MAX_VISIBLE_ASSIGNEES,
      );
    },
    isValidDateString,
  },
};
</script>
<template>
  <div>
    <paginated-table-with-search-and-tabs
      :show-items="showList"
      :show-error-msg="showErrorMsg"
      :i18n="$options.i18n"
      :items="
        incidents.list || [] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */
      "
      :page-info="incidents.pageInfo"
      :items-count="incidentsCount"
      :status-tabs="$options.statusTabs"
      :track-views-options="$options.trackIncidentListViewsOptions"
      filter-search-key="incidents"
      class="incident-management-list"
      @page-changed="pageChanged"
      @tabs-changed="statusChanged"
      @filters-changed="filtersChanged"
      @error-alert-dismissed="errorAlertDismissed"
    >
      <template #header-actions>
        <gl-button
          v-if="isHeaderButtonVisible"
          class="create-incident-button gl-my-3 gl-mr-5"
          data-testid="create-incident-button"
          :loading="redirecting"
          :disabled="redirecting"
          category="primary"
          variant="confirm"
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
          :items="
            incidents.list ||
            [] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */
          "
          :fields="availableFields"
          :busy="loading"
          stacked="md"
          :tbody-tr-class="tbodyTrClass"
          sort-direction="desc"
          :sort-desc.sync="sortDesc"
          sort-by="createdAt"
          show-empty
          no-local-sorting
          fixed
          hover
          selectable
          selected-variant="primary"
          @row-clicked="navigateToIncidentDetails"
          @sort-changed="fetchSortedData"
        >
          <template #cell(severity)="{ item }">
            <severity-token :severity="getSeverity(item.severity)" />
          </template>

          <template #cell(title)="{ item }">
            <div
              :class="{
                'gl-flex gl-max-w-full gl-items-center': isClosed(item),
              }"
            >
              <gl-link
                data-testid="incident-link"
                :href="showIncidentLink(item)"
                class="gl-min-w-0"
              >
                <tooltip-on-truncate :title="item.title" class="gl-block gl-truncate">
                  {{ item.title }}
                </tooltip-on-truncate>
              </gl-link>
              <gl-icon
                v-if="isClosed(item)"
                name="issue-close"
                class="gl-ml-2 gl-shrink-0 gl-fill-blue-500"
                :size="16"
                data-testid="incident-closed"
              />
            </div>
          </template>

          <template #cell(escalationStatus)="{ item }">
            <tooltip-on-truncate
              :title="getEscalationStatus(item.escalationStatus)"
              data-testid="incident-escalation-status"
              class="gl-block gl-truncate"
            >
              {{ getEscalationStatus(item.escalationStatus) }}
            </tooltip-on-truncate>
          </template>

          <template #cell(createdAt)="{ item }">
            <time-ago-tooltip :time="item.createdAt" class="gl-block gl-max-w-full gl-truncate" />
          </template>

          <template v-if="slaFeatureAvailable" #cell(incidentSla)="{ item }">
            <service-level-agreement-cell
              v-if="isValidDateString(item.slaDueAt)"
              :issue-iid="item.iid"
              :project-path="projectPath"
              :sla-due-at="item.slaDueAt"
              class="gl-block gl-max-w-full gl-truncate"
            />
          </template>

          <template #cell(assignees)="{ item }">
            <div data-testid="incident-assignees">
              <template v-if="hasAssignees(item.assignees)">
                <gl-avatars-inline
                  :avatars="item.assignees.nodes"
                  :collapsed="true"
                  :max-visible="$options.MAX_VISIBLE_ASSIGNEES"
                  :avatar-size="24"
                  badge-tooltip-prop="name"
                  :badge-tooltip-max-chars="100"
                  :badge-sr-only-text="assigneesBadgeSrOnlyText(item)"
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
