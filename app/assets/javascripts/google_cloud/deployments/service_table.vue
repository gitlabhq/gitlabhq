<script>
import { GlButton, GlTable } from '@gitlab/ui';
import { __ } from '~/locale';

const cloudRun = 'cloudRun';
const cloudStorage = 'cloudStorage';

const i18n = {
  cloudRun: __('Cloud Run'),
  cloudRunDescription: __('Deploy container based web apps on Google managed clusters'),
  cloudStorage: __('Cloud Storage'),
  cloudStorageDescription: __('Deploy static assets and resources to Google managed CDN'),
  deployments: __('Deployments'),
  deploymentsDescription: __(
    'Configure pipelines to deploy web apps, backend services, APIs and static resources to Google Cloud',
  ),
  configureViaMergeRequest: __('Configure via Merge Request'),
  service: __('Service'),
  description: __('Description'),
};

export default {
  components: { GlButton, GlTable },
  props: {
    cloudRunUrl: {
      type: String,
      required: true,
    },
    cloudStorageUrl: {
      type: String,
      required: true,
    },
  },
  methods: {
    actionUrl(key) {
      if (key === cloudRun) return this.cloudRunUrl;
      if (key === cloudStorage) return this.cloudStorageUrl;
      return '#';
    },
  },
  fields: [
    { key: 'title', label: i18n.service },
    { key: 'description', label: i18n.description },
    { key: 'action', label: '' },
  ],
  items: [
    {
      title: i18n.cloudRun,
      description: i18n.cloudRunDescription,
      action: {
        key: cloudRun,
        title: i18n.configureViaMergeRequest,
      },
    },
    {
      title: i18n.cloudStorage,
      description: i18n.cloudStorageDescription,
      action: {
        key: cloudStorage,
        title: i18n.configureViaMergeRequest,
        disabled: true,
      },
    },
  ],
  i18n,
};
</script>
<template>
  <div class="gl-mx-3">
    <h2 class="gl-text-size-h2">{{ $options.i18n.deployments }}</h2>
    <p>{{ $options.i18n.deploymentsDescription }}</p>
    <gl-table :fields="$options.fields" :items="$options.items">
      <template #cell(action)="{ value }">
        <gl-button :disabled="value.disabled" :href="actionUrl(value.key)">
          {{ value.title }}
        </gl-button>
      </template>
    </gl-table>
  </div>
</template>
