<script>
import { GlLoadingIcon, GlTable, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import getIncidents from '../graphql/queries/get_incidents.query.graphql';
import { I18N } from '../constants';

const tdClass =
  'table-col gl-display-flex d-md-table-cell gl-align-items-center gl-white-space-nowrap';
const thClass = 'gl-hover-bg-blue-50';
const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 gl-hover-bg-blue-50 gl-hover-border-b-solid gl-hover-border-blue-200';

export default {
  i18n: I18N,
  fields: [
    {
      key: 'title',
      label: s__('IncidentManagement|Incident'),
      thClass: `gl-pointer-events-none gl-w-half`,
      tdClass,
    },
    {
      key: 'createdAt',
      label: s__('IncidentManagement|Date created'),
      thClass: `${thClass} gl-pointer-events-none`,
      tdClass,
    },
    {
      key: 'assignees',
      label: s__('IncidentManagement|Assignees'),
      thClass: 'gl-pointer-events-none',
      tdClass,
    },
  ],
  components: {
    GlLoadingIcon,
    GlTable,
    GlAlert,
  },
  inject: ['projectPath'],
  apollo: {
    incidents: {
      query: getIncidents,
      variables() {
        return {
          projectPath: this.projectPath,
          labelNames: ['incident'],
        };
      },
      update: ({ project: { issues: { nodes = [] } = {} } = {} }) => nodes,
      error() {
        this.errored = true;
      },
    },
  },
  data() {
    return {
      errored: false,
      isErrorAlertDismissed: false,
    };
  },
  computed: {
    showErrorMsg() {
      return this.errored && !this.isErrorAlertDismissed;
    },
    loading() {
      return this.$apollo.queries.incidents.loading;
    },
    hasIncidents() {
      return this.incidents?.length;
    },
    tbodyTrClass() {
      return {
        [bodyTrClass]: !this.loading && this.hasIncidents,
      };
    },
  },
  methods: {
    getAssignees(assignees) {
      return assignees.nodes?.length > 0
        ? assignees.nodes[0]?.username
        : s__('IncidentManagement|Unassigned');
    },
  },
};
</script>
<template>
  <div class="incident-management-list">
    <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="isErrorAlertDismissed = true">
      {{ $options.i18n.errorMsg }}
    </gl-alert>

    <h4 class="gl-display-block d-md-none my-3">
      {{ s__('IncidentManagement|Incidents') }}
    </h4>
    <gl-table
      :items="incidents"
      :fields="$options.fields"
      :show-empty="true"
      :busy="loading"
      stacked="md"
      :tbody-tr-class="tbodyTrClass"
      :no-local-sorting="true"
      fixed
    >
      <template #cell(title)="{ item }">
        <div class="gl-max-w-full text-truncate" :title="item.title">{{ item.title }}</div>
      </template>

      <template #cell(createdAt)="{ item }">
        {{ item.createdAt }}
      </template>

      <template #cell(assignees)="{ item }">
        <div class="gl-max-w-full text-truncate" data-testid="assigneesField">
          {{ getAssignees(item.assignees) }}
        </div>
      </template>

      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="mt-3" />
      </template>

      <template #empty>
        {{ $options.i18n.noIncidents }}
      </template>
    </gl-table>
  </div>
</template>
