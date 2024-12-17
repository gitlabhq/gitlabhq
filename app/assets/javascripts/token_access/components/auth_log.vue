<script>
import {
  GlButton,
  GlIcon,
  GlKeysetPagination,
  GlLink,
  GlSprintf,
  GlTableLite,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __, sprintf, n__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import getAuthLogsQuery from '../graphql/queries/get_auth_logs.query.graphql';

const ENTRIES_PER_PAGE = 20;

export default {
  fields: [
    {
      key: 'fullPath',
      label: __('Project'),
      tdClass: 'gl-w-2/3',
    },
    {
      key: 'lastAuthorizedAt',
      label: __('Date'),
      tdClass: 'gl-w-1/3 gl-text-left !gl-align-middle',
    },
  ],
  name: 'CiJobTokensAuthLog',
  tokenLogCsvFileName: 'token_log_report.csv',
  ciJobTokenHelpPage: helpPagePath('ci/jobs/ci_job_token', {
    anchor: 'job-token-authentication-log',
  }),
  components: {
    GlButton,
    GlIcon,
    GlKeysetPagination,
    GlLink,
    GlSprintf,
    GlTableLite,
    CrudComponent,
    ProjectAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    fullPath: {
      default: '',
    },
    csvDownloadPath: {
      default: '',
    },
  },
  data() {
    return {
      authLogs: [],
      cursor: {
        first: ENTRIES_PER_PAGE,
        after: null,
        last: null,
        before: null,
      },
      pageInfo: {},
      logCount: 0,
    };
  },
  apollo: {
    authLogs: {
      query: getAuthLogsQuery,
      variables() {
        return this.queryVariables;
      },
      update({ project }) {
        this.logCount = project.ciJobTokenAuthLogs?.count;
        this.pageInfo = project.ciJobTokenAuthLogs?.pageInfo;

        return project.ciJobTokenAuthLogs?.nodes || [];
      },
      error() {
        createAlert({
          message: s__('CICD|There was a problem fetching authentication logs.'),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.authLogs.loading;
    },
    showPagination() {
      return (this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage) && this.logCount <= 100;
    },
    queryVariables() {
      return {
        fullPath: this.fullPath,
        ...this.cursor,
      };
    },
    logCountTooltip() {
      return sprintf(
        n__('%{count} event has ocurred', '%{count} events have ocurred', this.logCount),
        {
          count: this.logCount,
        },
      );
    },
    displayLogEventsTable() {
      return !this.isLoading && this.logCount > 0 && this.logCount <= 100;
    },
  },
  methods: {
    nextPage(item) {
      this.cursor = {
        first: ENTRIES_PER_PAGE,
        after: item,
        last: null,
        before: null,
      };
    },
    prevPage(item) {
      this.cursor = {
        first: null,
        after: null,
        last: ENTRIES_PER_PAGE,
        before: item,
      };
    },
  },
};
</script>
<template>
  <div>
    <crud-component :title="s__('CICD|Authentication log')" class="gl-mt-5">
      <template #count>
        <span
          v-gl-tooltip
          :title="logCountTooltip"
          class="gl-inline-flex gl-items-center gl-gap-2 gl-text-sm gl-text-subtle"
          data-testid="log-count"
        >
          <gl-icon name="log" />
          {{ logCount }}
        </span>
      </template>
      <template #actions>
        <gl-button
          v-if="!isLoading && logCount > 0"
          is-unsafe-link
          size="small"
          :href="csvDownloadPath"
          :title="__('Download CSV')"
          :download="$options.tokenLogCsvFileName"
          data-testid="auth-log-download-csv-button"
          >{{ __('Download CSV') }}</gl-button
        >
      </template>
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'CICD|Authentication events from the last 30 days. %{linkStart}Learn more.%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.ciJobTokenHelpPage" class="inline-link" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <gl-table-lite
        v-if="displayLogEventsTable"
        :items="authLogs"
        :fields="$options.fields"
        :tbody-tr-attr="{ 'data-testid': 'auth-logs-table-row' }"
        class="gl-mb-0"
        fixed
      >
        <template #cell(fullPath)="{ item }">
          <div class="gl-inline-flex gl-items-center">
            <gl-icon name="project" class="gl-mr-3 gl-shrink-0" />
            <project-avatar
              :alt="item.originProject.name"
              :project-avatar-url="item.originProject.avatarUrl"
              :project-id="item.originProject.id"
              :project-name="item.originProject.name"
              class="gl-mr-3"
              :size="24"
            />
            <span class="gl-text-default">{{ item.originProject.fullPath }}</span>
          </div>
        </template>
      </gl-table-lite>
      <div
        v-if="!isLoading && logCount > 100"
        class="gl-text-center"
        data-testid="auth-logs-too-many-text"
      >
        {{
          s__(
            'CICD|There are too many entries to display. Download the CSV file to view the full log.',
          )
        }}
      </div>
      <div
        v-if="!isLoading && logCount === 0"
        class="gl-text-center"
        data-testid="auth-logs-no-events"
      >
        {{ s__('CICD|No authentication events in the last 30 days.') }}
      </div>
    </crud-component>
    <gl-keyset-pagination
      v-if="showPagination"
      v-bind="pageInfo"
      class="gl-mt-3 gl-self-center"
      data-testid="auth-log-pagination"
      @prev="prevPage"
      @next="nextPage"
    />
  </div>
</template>
