<script>
import { GlTable, GlLink, GlPagination, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { getParameterValues, setUrlParams } from '~/lib/utils/url_utility';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import IncubationAlert from './incubation_alert.vue';

export default {
  name: 'MlExperiment',
  components: {
    GlTable,
    GlLink,
    TimeAgo,
    IncubationAlert,
    GlPagination,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['candidates', 'metricNames', 'paramNames', 'pagination'],
  data() {
    return {
      page: parseInt(getParameterValues('page')[0], 10) || 1,
    };
  },
  computed: {
    fields() {
      return [
        { key: 'name', label: this.$options.i18n.nameLabel },
        { key: 'created_at', label: this.$options.i18n.createdAtLabel },
        { key: 'user', label: this.$options.i18n.userLabel },
        ...this.paramNames,
        ...this.metricNames,
        { key: 'details', label: '' },
        { key: 'artifact', label: '' },
      ];
    },
    displayPagination() {
      return this.candidates.length > 0;
    },
    prevPage() {
      return this.pagination.page > 1 ? this.pagination.page - 1 : null;
    },
    nextPage() {
      return !this.pagination.isLastPage ? this.pagination.page + 1 : null;
    },
  },
  methods: {
    generateLink(page) {
      return setUrlParams({ page });
    },
  },
  i18n: {
    titleLabel: __('Experiment candidates'),
    emptyStateLabel: __('This experiment has no logged candidates'),
    artifactsLabel: __('Artifacts'),
    detailsLabel: __('Details'),
    userLabel: __('User'),
    createdAtLabel: __('Created at'),
    nameLabel: __('Name'),
    noDataContent: __('-'),
  },
};
</script>

<template>
  <div>
    <incubation-alert />

    <h3>
      {{ $options.i18n.titleLabel }}
    </h3>

    <gl-table
      :fields="fields"
      :items="candidates"
      :empty-text="$options.i18n.emptyStateLabel"
      show-empty
      small
      class="gl-mt-0! ml-candidate-table"
    >
      <template #cell()="data">
        <div v-gl-tooltip.hover :title="data.value">{{ data.value }}</div>
      </template>

      <template #cell(artifact)="data">
        <gl-link
          v-if="data.value"
          v-gl-tooltip.hover
          :href="data.value"
          target="_blank"
          :title="$options.i18n.artifactsLabel"
          >{{ $options.i18n.artifactsLabel }}</gl-link
        >
        <div v-else v-gl-tooltip.hover :title="$options.i18n.artifactsLabel">
          {{ $options.i18n.noDataContent }}
        </div>
      </template>

      <template #cell(details)="data">
        <gl-link v-gl-tooltip.hover :href="data.value" :title="$options.i18n.detailsLabel">{{
          $options.i18n.detailsLabel
        }}</gl-link>
      </template>

      <template #cell(created_at)="data">
        <time-ago v-gl-tooltip.hover :time="data.value" :title="data.value" />
      </template>

      <template #cell(user)="data">
        <gl-link
          v-if="data.value"
          v-gl-tooltip.hover
          :href="data.value.path"
          :title="data.value.username"
          >@{{ data.value.username }}</gl-link
        >
        <div v-else>{{ $options.i18n.noDataContent }}</div>
      </template>
    </gl-table>

    <gl-pagination
      v-if="displayPagination"
      v-model="pagination.page"
      :prev-page="prevPage"
      :next-page="nextPage"
      :total-items="pagination.totalItems"
      :per-page="pagination.perPage"
      :link-gen="generateLink"
      align="center"
      class="w-100"
    />
  </div>
</template>
