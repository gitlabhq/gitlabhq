<script>
import { mapState, mapActions } from 'vuex';
import { GlTable, GlLink, GlLoadingIcon, GlBadge } from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';
import { CLUSTER_TYPES, STATUSES } from '../constants';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlTable,
    GlLink,
    GlLoadingIcon,
    GlBadge,
  },
  directives: {
    tooltip,
  },
  computed: {
    ...mapState(['clusters', 'loading']),
    fields() {
      return [
        {
          key: 'name',
          label: __('Kubernetes cluster'),
        },
        {
          key: 'environment_scope',
          label: __('Environment scope'),
        },
        // Wait for backend to send these fields
        // {
        //  key: 'size',
        //  label: __('Size'),
        // },
        // {
        //  key: 'cpu',
        //  label: __('Total cores (vCPUs)'),
        // },
        // {
        //  key: 'memory',
        //  label: __('Total memory (GB)'),
        // },
        {
          key: 'cluster_type',
          label: __('Cluster level'),
          formatter: value => CLUSTER_TYPES[value],
        },
      ];
    },
  },
  mounted() {
    this.fetchClusters();
  },
  methods: {
    ...mapActions(['fetchClusters']),
    statusClass(status) {
      const iconClass = STATUSES[status] || STATUSES.default;
      return iconClass.className;
    },
    statusTitle(status) {
      const iconTitle = STATUSES[status] || STATUSES.default;
      return sprintf(__('Status: %{title}'), { title: iconTitle.title }, false);
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" size="md" class="mt-3" />
  <gl-table v-else :items="clusters" :fields="fields" stacked="md" class="qa-clusters-table">
    <template #cell(name)="{ item }">
      <div class="d-flex flex-row-reverse flex-md-row js-status">
        <gl-link data-qa-selector="cluster" :data-qa-cluster-name="item.name" :href="item.path">
          {{ item.name }}
        </gl-link>

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
          class="cluster-status-indicator rounded-circle align-self-center gl-w-4 gl-h-4 mr-2 ml-md-2"
          :class="statusClass(item.status)"
          :title="statusTitle(item.status)"
        ></div>
      </div>
    </template>
    <template #cell(cluster_type)="{value}">
      <gl-badge variant="light">
        {{ value }}
      </gl-badge>
    </template>
  </gl-table>
</template>
