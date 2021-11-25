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
  data() {
    return {
      tableFields: [
        { key: 'environment', label: __('Environment'), sortable: true },
        { key: 'gcp_project', label: __('Google Cloud Project'), sortable: true },
        { key: 'service_account_exists', label: __('Service Account'), sortable: true },
        { key: 'service_account_key_exists', label: __('Service Account Key'), sortable: true },
      ],
    };
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="list.length === 0"
      :title="__('No service accounts')"
      :description="
        __('Service Accounts keys authorize GitLab to deploy your Google Cloud project')
      "
      :primary-button-link="createUrl"
      :primary-button-text="__('Create service account')"
      :svg-path="emptyIllustrationUrl"
    />

    <div v-else>
      <h2 class="gl-font-size-h2">{{ __('Service Accounts') }}</h2>
      <p>{{ __('Service Accounts keys authorize GitLab to deploy your Google Cloud project') }}</p>

      <gl-table :items="list" :fields="tableFields">
        <template #cell(service_account_exists)="{ value }">
          {{ value ? '✔' : __('Not found') }}
        </template>
        <template #cell(service_account_key_exists)="{ value }">
          {{ value ? '✔' : __('Not found') }}
        </template>
      </gl-table>

      <gl-button :href="createUrl" category="primary" variant="info">
        {{ __('Create service account') }}
      </gl-button>
    </div>
  </div>
</template>
