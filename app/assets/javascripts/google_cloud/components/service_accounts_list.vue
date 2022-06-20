<script>
import { GlAlert, GlButton, GlEmptyState, GlLink, GlSprintf, GlTable } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlAlert, GlButton, GlEmptyState, GlLink, GlSprintf, GlTable },
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
    { key: 'ref', label: __('Environment'), sortable: true },
    { key: 'gcp_project', label: __('Google Cloud Project'), sortable: true },
    { key: 'service_account_exists', label: __('Service Account'), sortable: true },
    { key: 'service_account_key_exists', label: __('Service Account Key'), sortable: true },
  ],
  i18n: {
    createServiceAccount: __('Create service account'),
    found: __('✔'),
    notFound: __('Not found'),
    noServiceAccountsTitle: __('No service accounts'),
    noServiceAccountsDescription: __(
      'Service Accounts keys authorize GitLab to deploy your Google Cloud project',
    ),
    serviceAccountsTitle: __('Service accounts'),
    serviceAccountsDescription: __(
      'Service Accounts keys authorize GitLab to deploy your Google Cloud project',
    ),
    secretManagersDescription: __(
      'Enhance security by storing service account keys in secret managers - learn more about %{docLinkStart}secret management with GitLab%{docLinkEnd}',
    ),
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="list.length === 0"
      :title="$options.i18n.noServiceAccountsTitle"
      :description="$options.i18n.noServiceAccountsDescription"
      :primary-button-link="createUrl"
      :primary-button-text="$options.i18n.createServiceAccount"
      :svg-path="emptyIllustrationUrl"
    />

    <div v-else>
      <h2 class="gl-font-size-h2">{{ $options.i18n.serviceAccountsTitle }}</h2>
      <p>{{ $options.i18n.serviceAccountsDescription }}</p>

      <gl-table :items="list" :fields="$options.tableFields">
        <template #cell(service_account_exists)="{ value }">
          {{ value ? $options.i18n.found : $options.i18n.notFound }}
        </template>
        <template #cell(service_account_key_exists)="{ value }">
          {{ value ? $options.i18n.found : $options.i18n.notFound }}
        </template>
      </gl-table>

      <gl-button :href="createUrl" category="primary" variant="confirm">
        {{ $options.i18n.createServiceAccount }}
      </gl-button>

      <gl-alert class="gl-mt-5" :dismissible="false" variant="tip">
        <gl-sprintf :message="$options.i18n.secretManagersDescription">
          <template #docLink="{ content }">
            <gl-link href="https://docs.gitlab.com/ee/ci/secrets/">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
    </div>
  </div>
</template>
