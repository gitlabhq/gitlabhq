<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import UsageGraph from '~/vue_shared/components/storage_counter/usage_graph.vue';
import getProjectStorageCount from '../queries/project_storage.query.graphql';
import { parseGetProjectStorageResults } from '../utils';

export default {
  name: 'StorageCounterApp',
  components: {
    GlAlert,
    UsageGraph,
  },
  inject: ['projectPath'],
  apollo: {
    project: {
      query: getProjectStorageCount,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update: parseGetProjectStorageResults,
      error() {
        this.error = s__(
          'UsageQuota|Something went wrong while fetching project storage statistics',
        );
      },
    },
  },
  data() {
    return {
      project: {},
      error: '',
    };
  },
  methods: {
    clearError() {
      this.error = '';
    },
  },
  i18n: {
    placeholder: s__('UsageQuota|Usage'),
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="clearError">
      {{ error }}
    </gl-alert>
    <div v-else>{{ $options.i18n.placeholder }}</div>
    <div v-if="project.statistics" class="gl-w-full">
      <usage-graph :root-storage-statistics="project.statistics" :limit="0" />
    </div>
  </div>
</template>
