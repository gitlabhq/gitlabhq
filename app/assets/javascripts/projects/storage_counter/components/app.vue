<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import getProjectStorageCount from '../queries/project_storage.query.graphql';
import { parseGetProjectStorageResults } from '../utils';

export default {
  name: 'StorageCounterApp',
  components: {
    GlAlert,
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
  <gl-alert v-if="error" variant="danger" @dismiss="clearError">
    {{ error }}
  </gl-alert>
  <div v-else>{{ $options.i18n.placeholder }}</div>
</template>
