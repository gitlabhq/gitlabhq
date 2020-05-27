<script>
import { mapState, mapActions } from 'vuex';
import {
  GlDeprecatedBadge as GlBadge,
  GlLink,
  GlLoadingIcon,
  GlPagination,
  GlTable,
} from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';
import { CLUSTER_TYPES, STATUSES } from '../constants';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlBadge,
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlTable,
  },
  directives: {
    tooltip,
  },
  computed: {
    ...mapState(['clusters', 'clustersPerPage', 'loading', 'page', 'totalCulsters']),
    currentPage: {
      get() {
        return this.page;
      },
      set(newVal) {
        this.setPage(newVal);
        this.fetchClusters();
      },
    },
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
        {
          key: 'node_size',
          label: __('Nodes'),
        },
        // Fields are missing calculation methods and not ready to display
        // {
        //  key: 'node_cpu',
        //  label: __('Total cores (vCPUs)'),
        // },
        // {
        //  key: 'node_memory',
        //  label: __('Total memory (GB)'),
        // },
        {
          key: 'cluster_type',
          label: __('Cluster level'),
          formatter: value => CLUSTER_TYPES[value],
        },
      ];
    },
    hasClusters() {
      return this.clustersPerPage > 0;
    },
  },
  mounted() {
    this.fetchClusters();
  },
  methods: {
    ...mapActions(['fetchClusters', 'setPage']),
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

  <section v-else>
    <gl-table :items="clusters" :fields="fields" stacked="md" class="qa-clusters-table">
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

      <template #cell(node_size)="{ item }">
        <span v-if="item.nodes">{{ item.nodes.length }}</span>
        <small v-else class="gl-font-sm gl-font-style-italic gl-text-gray-400">{{
          __('Unknown')
        }}</small>
      </template>

      <template #cell(cluster_type)="{value}">
        <gl-badge variant="light">
          {{ value }}
        </gl-badge>
      </template>
    </gl-table>

    <gl-pagination
      v-if="hasClusters"
      v-model="currentPage"
      :per-page="clustersPerPage"
      :total-items="totalCulsters"
      :prev-text="__('Prev')"
      :next-text="__('Next')"
      align="center"
    />
  </section>
</template>
