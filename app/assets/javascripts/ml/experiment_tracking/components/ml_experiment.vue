<script>
import { GlTable, GlLink, GlPagination } from '@gitlab/ui';
import { __ } from '~/locale';
import { getParameterValues, setUrlParams } from '~/lib/utils/url_utility';
import IncubationAlert from './incubation_alert.vue';

export default {
  name: 'MlExperiment',
  components: {
    GlTable,
    GlLink,
    IncubationAlert,
    GlPagination,
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
      class="gl-mt-0!"
      small
    >
      <template #cell(artifact)="data">
        <gl-link v-if="data.value" :href="data.value" target="_blank">{{
          $options.i18n.artifactsLabel
        }}</gl-link>
      </template>

      <template #cell(details)="data">
        <gl-link :href="data.value">{{ $options.i18n.detailsLabel }}</gl-link>
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
