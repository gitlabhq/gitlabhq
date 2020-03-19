<script>
import { mapState, mapActions } from 'vuex';
import { GlTable, GlLoadingIcon, GlBadge } from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';
import { CLUSTER_TYPES, STATUSES } from '../constants';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlTable,
    GlLoadingIcon,
    GlBadge,
  },
  directives: {
    tooltip,
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
      key: 'cpu',
      label: __('Total cores (vCPUs)'),
    },
    {
      key: 'memory',
      label: __('Total memory (GB)'),
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
    statusClass(status) {
      return STATUSES[status].className;
    },
    statusTitle(status) {
      const { title } = STATUSES[status];
      return sprintf(__('Status: %{title}'), { title }, false);
    },
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
    <template #cell(name)="{ item }">
      <div class="d-flex flex-row-reverse flex-md-row js-status">
        {{ item.name }}
        <gl-loading-icon
          v-if="item.status === 'deleting'"
          v-tooltip
          :title="statusTitle(item.status)"
          size="sm"
          class="mr-2 ml-md-2"
        />
        <div
          v-else
          v-tooltip
          class="cluster-status-indicator rounded-circle align-self-center gl-w-8 gl-h-8 mr-2 ml-md-2"
          :class="statusClass(item.status)"
          :title="statusTitle(item.status)"
        ></div>
      </div>
    </template>
    <template #cell(clusterType)="{value}">
      <gl-badge variant="light">
        {{ value }}
      </gl-badge>
    </template>
  </gl-table>
</template>
