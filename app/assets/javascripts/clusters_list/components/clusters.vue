<!-- eslint-disable vue/multi-word-component-names -->
<script>
import {
  GlBadge,
  GlLink,
  GlLoadingIcon,
  GlPagination,
  GlSkeletonLoader,
  GlSprintf,
  GlTableLite,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { __, sprintf } from '~/locale';
import { CLUSTER_TYPES, STATUSES } from '../constants';
import AncestorNotice from './ancestor_notice.vue';
import NodeErrorHelpText from './node_error_help_text.vue';
import ClustersEmptyState from './clusters_empty_state.vue';

export default {
  nodeMemoryText: __('%{totalMemory} (%{freeSpacePercentage}%{percentSymbol} free)'),
  nodeCpuText: __('%{totalCpu} (%{freeSpacePercentage}%{percentSymbol} free)'),
  components: {
    AncestorNotice,
    GlBadge,
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlSkeletonLoader,
    GlSprintf,
    GlTableLite,
    NodeErrorHelpText,
    ClustersEmptyState,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isChildComponent: {
      default: false,
      required: false,
      type: Boolean,
    },
    limit: {
      default: null,
      required: false,
      type: Number,
    },
  },
  computed: {
    ...mapState([
      'clusters',
      'clustersPerPage',
      'loadingClusters',
      'loadingNodes',
      'page',
      'providers',
      'totalClusters',
    ]),
    contentAlignClasses() {
      return 'gl-flex gl-items-center gl-justify-end md:gl-justify-start';
    },
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
      const tdClass = '!gl-py-5';
      return [
        {
          key: 'name',
          label: __('Kubernetes cluster'),
          isRowHeader: true,
          tdClass,
        },
        {
          key: 'environment_scope',
          label: __('Environment scope'),
          tdClass,
        },
        {
          key: 'node_size',
          label: __('Nodes'),
          tdClass,
        },
        {
          key: 'total_cpu',
          label: __('Total cores (CPUs)'),
          tdClass,
        },
        {
          key: 'total_memory',
          label: __('Total memory (GB)'),
          tdClass,
        },
        {
          key: 'cluster_type',
          label: __('Cluster level'),
          tdClass,
          formatter: (value) => CLUSTER_TYPES[value],
        },
      ];
    },
    hasClustersPerPage() {
      return this.clustersPerPage > 0;
    },
    hasClusters() {
      return this.totalClusters > 0;
    },
  },
  mounted() {
    if (this.limit) {
      this.setClustersPerPage(this.limit);
    }

    this.fetchClusters();
  },
  methods: {
    ...mapActions(['fetchClusters', 'reportSentryError', 'setPage', 'setClustersPerPage']),
    k8sQuantityToGb(quantity) {
      if (!quantity) {
        return 0;
      }
      if (quantity.endsWith(__('Ki'))) {
        return parseInt(quantity.substr(0, quantity.length - 2), 10) * 0.000001024;
      }
      if (quantity.endsWith(__('Mi'))) {
        return parseInt(quantity.substr(0, quantity.length - 2), 10) * 0.001048576;
      }

      // We are trying to track quantity types coming from Kubernetes.
      // Sentry will notify us if we are missing types.
      throw new Error(`UnknownK8sMemoryQuantity:${quantity}`);
    },
    k8sQuantityToCpu(quantity) {
      if (!quantity) {
        return 0;
      }
      if (quantity.endsWith('m')) {
        return parseInt(quantity.substr(0, quantity.length - 1), 10) / 1000.0;
      }
      if (quantity.endsWith('n')) {
        return parseInt(quantity.substr(0, quantity.length - 1), 10) / 1000000000.0;
      }

      // We are trying to track quantity types coming from Kubernetes.
      // Sentry will notify us if we are missing types.
      throw new Error(`UnknownK8sCpuQuantity:${quantity}`);
    },
    selectedProvider(provider) {
      return this.providers[provider] || this.providers.default;
    },
    statusTitle(status) {
      const iconTitle = STATUSES[status] || STATUSES.default;
      return sprintf(__('Status: %{title}'), { title: iconTitle.title }, false);
    },
    totalMemoryAndUsage(nodes) {
      try {
        // For EKS node.usage will not be present unless the user manually
        // install the metrics server
        if (nodes && nodes[0].usage) {
          let totalAllocatableMemory = 0;
          let totalUsedMemory = 0;

          nodes.reduce((total, node) => {
            const allocatableMemoryQuantity = node.status.allocatable.memory;
            const allocatableMemoryGb = this.k8sQuantityToGb(allocatableMemoryQuantity);
            totalAllocatableMemory += allocatableMemoryGb;

            const usedMemoryQuantity = node.usage.memory;
            const usedMemoryGb = this.k8sQuantityToGb(usedMemoryQuantity);
            totalUsedMemory += usedMemoryGb;

            return null;
          }, 0);

          const freeSpacePercentage = (1 - totalUsedMemory / totalAllocatableMemory) * 100;

          return {
            totalMemory: totalAllocatableMemory.toFixed(2),
            freeSpacePercentage: Math.round(freeSpacePercentage),
          };
        }
      } catch (error) {
        this.reportSentryError({ error, tag: 'totalMemoryAndUsageError' });
      }

      return { totalMemory: null, freeSpacePercentage: null };
    },
    totalCpuAndUsage(nodes) {
      try {
        // For EKS node.usage will not be present unless the user manually
        // install the metrics server
        if (nodes && nodes[0].usage) {
          let totalAllocatableCpu = 0;
          let totalUsedCpu = 0;

          nodes.reduce((total, node) => {
            const allocatableCpuQuantity = node.status.allocatable.cpu;
            const allocatableCpu = this.k8sQuantityToCpu(allocatableCpuQuantity);
            totalAllocatableCpu += allocatableCpu;

            const usedCpuQuantity = node.usage.cpu;
            const usedCpuGb = this.k8sQuantityToCpu(usedCpuQuantity);
            totalUsedCpu += usedCpuGb;

            return null;
          }, 0);

          const freeSpacePercentage = (1 - totalUsedCpu / totalAllocatableCpu) * 100;

          return {
            totalCpu: totalAllocatableCpu.toFixed(2),
            freeSpacePercentage: Math.round(freeSpacePercentage),
          };
        }
      } catch (error) {
        this.reportSentryError({ error, tag: 'totalCpuAndUsageError' });
      }

      return { totalCpu: null, freeSpacePercentage: null };
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="loadingClusters" size="lg" />

  <section v-else>
    <ancestor-notice />

    <gl-table-lite
      v-if="hasClusters"
      :items="clusters"
      :fields="fields"
      fixed
      stacked="md"
      class="!gl-mb-4"
      data-testid="cluster_list_table"
    >
      <template #cell(name)="{ item }">
        <div :class="[contentAlignClasses, 'js-status']">
          <img
            :src="selectedProvider(item.provider_type).path"
            :alt="selectedProvider(item.provider_type).text"
            class="gl-flex gl-h-6 gl-w-6 gl-items-center"
          />

          <gl-link :href="item.path" class="gl-px-3 gl-font-normal">
            {{ item.name }}
          </gl-link>

          <gl-loading-icon
            v-if="item.status === 'deleting' || item.status === 'creating'"
            v-gl-tooltip
            :title="statusTitle(item.status)"
            size="sm"
          />
        </div>
      </template>

      <template #cell(node_size)="{ item }">
        <span v-if="item.nodes">{{ item.nodes.length }}</span>

        <gl-skeleton-loader v-else-if="loadingNodes" :lines="1" :class="contentAlignClasses" />

        <node-error-help-text
          v-else-if="item.kubernetes_errors"
          :class="contentAlignClasses"
          :error-type="item.kubernetes_errors.connection_error"
          :popover-id="`nodeSizeError${item.id}`"
        />
      </template>

      <template #cell(total_cpu)="{ item }">
        <span v-if="item.nodes">
          <gl-sprintf :message="$options.nodeCpuText">
            <template #totalCpu>{{ totalCpuAndUsage(item.nodes).totalCpu }}</template>
            <template #freeSpacePercentage>{{
              totalCpuAndUsage(item.nodes).freeSpacePercentage
            }}</template>
            <template #percentSymbol>%</template>
          </gl-sprintf>
        </span>

        <gl-skeleton-loader v-else-if="loadingNodes" :lines="1" :class="contentAlignClasses" />

        <node-error-help-text
          v-else-if="item.kubernetes_errors"
          :class="contentAlignClasses"
          :error-type="item.kubernetes_errors.node_connection_error"
          :popover-id="`nodeCpuError${item.id}`"
        />
      </template>

      <template #cell(total_memory)="{ item }">
        <span v-if="item.nodes">
          <gl-sprintf :message="$options.nodeMemoryText">
            <template #totalMemory>{{ totalMemoryAndUsage(item.nodes).totalMemory }}</template>
            <template #freeSpacePercentage>{{
              totalMemoryAndUsage(item.nodes).freeSpacePercentage
            }}</template>
            <template #percentSymbol>%</template>
          </gl-sprintf>
        </span>

        <gl-skeleton-loader v-else-if="loadingNodes" :lines="1" :class="contentAlignClasses" />

        <node-error-help-text
          v-else-if="item.kubernetes_errors"
          :class="contentAlignClasses"
          :error-type="item.kubernetes_errors.metrics_connection_error"
          :popover-id="`nodeMemoryError${item.id}`"
        />
      </template>

      <template #cell(cluster_type)="{ value }">
        <gl-badge variant="muted">
          {{ value }}
        </gl-badge>
      </template>
    </gl-table-lite>

    <clusters-empty-state v-else :is-child-component="isChildComponent" />

    <gl-pagination
      v-if="hasClustersPerPage && !limit"
      v-model="currentPage"
      :per-page="clustersPerPage"
      :total-items="totalClusters"
      align="center"
    />
  </section>
</template>
