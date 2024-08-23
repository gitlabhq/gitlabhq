<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlEmptyState, GlTable } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlButton, GlEmptyState, GlTable },
  props: {
    list: {
      type: Array,
      required: true,
    },
    createUrl: {
      type: String,
      required: true,
    },
    emptyIllustrationUrl: {
      type: String,
      required: true,
    },
  },
  tableFields: [
    { key: 'environment', label: __('Environment'), sortable: true },
    { key: 'gcp_region', label: __('Region'), sortable: true },
  ],
  i18n: {
    emptyStateTitle: __('No regions configured'),
    description: __('Configure your environments to be deployed to specific geographical regions'),
    emptyStateAction: __('Add a GCP region'),
    configureRegions: __('Configure regions'),
    listTitle: __('Regions'),
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="list.length === 0"
      :title="$options.i18n.emptyStateTitle"
      :description="$options.i18n.description"
      :primary-button-link="createUrl"
      :primary-button-text="$options.i18n.configureRegions"
    />

    <div v-else>
      <h2 class="gl-text-size-h2">{{ $options.i18n.listTitle }}</h2>
      <p>{{ $options.i18n.description }}</p>

      <gl-table :items="list" :fields="$options.tableFields" />

      <gl-button :href="createUrl" category="primary" variant="confirm">
        {{ $options.i18n.configureRegions }}
      </gl-button>
    </div>
  </div>
</template>
