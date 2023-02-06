<script>
import { GlTableLite, GlEmptyState, GlPagination, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { setUrlParams } from '~/lib/utils/url_utility';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import IncubationAlert from './incubation_alert.vue';

export default {
  name: 'AirflowDags',
  components: {
    GlTableLite,
    GlEmptyState,
    IncubationAlert,
    GlPagination,
    TimeAgo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    dags: {
      type: Array,
      required: true,
    },
    pagination: {
      type: Object,
      required: true,
    },
  },
  computed: {
    fields() {
      return [
        { key: 'dag_name', label: this.$options.i18n.dagLabel },
        { key: 'schedule', label: this.$options.scheduleLabel },
        { key: 'next_run', label: this.$options.nextRunLabel },
        { key: 'is_active', label: this.$options.isActiveLabel },
        { key: 'is_paused', label: this.$options.isPausedLabel },
        { key: 'fileloc', label: this.$options.fileLocLabel },
      ];
    },
    hasPagination() {
      return this.dags.length > 0;
    },
    prevPage() {
      return this.pagination.page > 1 ? this.pagination.page - 1 : null;
    },
    nextPage() {
      return !this.pagination.isLastPage ? this.pagination.page + 1 : null;
    },
    emptyState() {
      return {
        svgPath: '/assets/illustrations/empty-state/empty-dag-md.svg',
      };
    },
  },
  methods: {
    generateLink(page) {
      return setUrlParams({ page });
    },
    formatDate(dateString) {
      return formatDate(new Date(dateString));
    },
  },
  i18n: {
    emptyStateLabel: s__('Airflow|There are no DAGs to show'),
    emptyStateDescription: s__(
      'Airflow|Either the Airflow instance does not contain DAGs or has yet to be configured',
    ),
    dagLabel: s__('Airflow|DAG'),
    scheduleLabel: s__('Airflow|Schedule'),
    nextRunLabel: s__('Airflow|Next run'),
    isActiveLabel: s__('Airflow|Is active'),
    isPausedLabel: s__('Airflow|Is paused'),
    fileLocLabel: s__('Airflow|DAG file location'),
  },
};
</script>

<template>
  <div>
    <incubation-alert />
    <gl-empty-state
      v-if="!dags.length"
      :title="$options.i18n.emptyStateLabel"
      :description="$options.i18n.emptyStateDescription"
      :svg-path="emptyState.svgPath"
    />
    <gl-table-lite v-else :items="dags" :fields="fields" class="gl-mt-0!">
      <template #cell(next_run)="data">
        <time-ago v-gl-tooltip.hover :time="data.value" :title="formatDate(data.value)" />
      </template>
    </gl-table-lite>
    <gl-pagination
      v-if="hasPagination"
      :value="pagination.page"
      :prev-page="prevPage"
      :next-page="nextPage"
      :total-items="pagination.totalItems"
      :per-page="pagination.perPage"
      :link-gen="generateLink"
      align="center"
    />
  </div>
</template>
