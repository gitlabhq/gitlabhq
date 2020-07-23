<script>
import {
  GlLoadingIcon,
  GlTable,
  GlAlert,
  GlAvatarsInline,
  GlAvatarLink,
  GlAvatar,
  GlTooltipDirective,
} from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
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
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
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
        <time-ago-tooltip :time="item.createdAt" />
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

      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="mt-3" />
      </template>

      <template #empty>
        {{ $options.i18n.noIncidents }}
      </template>
    </gl-table>
  </div>
</template>
