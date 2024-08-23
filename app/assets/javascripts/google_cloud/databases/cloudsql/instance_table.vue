<script>
import { GlEmptyState, GlLink, GlTable } from '@gitlab/ui';
import { encodeSaferUrl, setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

const i18n = {
  noInstancesTitle: s__('CloudSeed|No instances'),
  noInstancesDescription: s__('CloudSeed|There are no instances to display.'),
  title: s__('CloudSeed|Instances'),
  description: s__('CloudSeed|Database instances associated with this project'),
};

export default {
  components: { GlEmptyState, GlLink, GlTable },
  props: {
    cloudsqlInstances: {
      type: Array,
      required: true,
    },
    emptyIllustrationUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    tableData() {
      return this.cloudsqlInstances.filter((instance) => instance.instance_name);
    },
  },
  methods: {
    gcpProjectUrl(id) {
      return setUrlParams({ project: id }, 'https://console.cloud.google.com/sql/instances');
    },
    instanceUrl(name, id) {
      const saferName = encodeSaferUrl(name);

      return setUrlParams(
        { project: id },
        `https://console.cloud.google.com/sql/instances/${saferName}/overview`,
      );
    },
  },
  fields: [
    { key: 'ref', label: s__('CloudSeed|Environment') },
    { key: 'gcp_project', label: s__('CloudSeed|Google Cloud Project') },
    { key: 'instance_name', label: s__('CloudSeed|CloudSQL Instance') },
    { key: 'version', label: s__('CloudSeed|Version') },
  ],
  i18n,
};
</script>

<template>
  <div class="gl-mx-3">
    <gl-empty-state
      v-if="tableData.length === 0"
      :title="$options.i18n.noInstancesTitle"
      :description="$options.i18n.noInstancesDescription"
      :svg-path="emptyIllustrationUrl"
      :svg-height="null"
    />

    <div v-else>
      <h2 class="gl-text-size-h2">{{ $options.i18n.title }}</h2>
      <p>{{ $options.i18n.description }}</p>
      <gl-table :fields="$options.fields" :items="tableData">
        <template #cell(gcp_project)="{ value }">
          <gl-link :href="gcpProjectUrl(value)">{{ value }}</gl-link>
        </template>
        <template #cell(instance_name)="{ item: { instance_name, gcp_project } }">
          <a :href="instanceUrl(instance_name, gcp_project)">{{ instance_name }}</a>
        </template>
      </gl-table>
    </div>
  </div>
</template>
