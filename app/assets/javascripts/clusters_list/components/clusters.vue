<script>
import { mapState, mapActions } from 'vuex';
import { GlTable, GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { CLUSTER_TYPES } from '../constants';
import { __ } from '~/locale';

export default {
  components: {
    GlTable,
    GlLoadingIcon,
    GlBadge,
  },
  fields: [
    {
      key: 'name',
      label: __('Kubernetes cluster'),
    },
    {
      key: 'environmentScope',
      label: __('Environment scope'),
    },
    {
      key: 'size',
      label: __('Size'),
    },
    {
      key: 'clusterType',
      label: __('Cluster level'),
      formatter: value => CLUSTER_TYPES[value],
    },
  ],
  computed: {
    ...mapState(['clusters', 'loading']),
  },
  mounted() {
    // TODO - uncomment this once integrated with BE
    // this.fetchClusters();
  },
  methods: {
    ...mapActions(['fetchClusters']),
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" size="md" class="mt-3" />
  <gl-table
    v-else
    :items="clusters"
    :fields="$options.fields"
    stacked="md"
    variant="light"
    class="qa-clusters-table"
  >
    <template #cell(clusterType)="{value}">
      <gl-badge variant="light">
        {{ value }}
      </gl-badge>
    </template>
  </gl-table>
</template>
