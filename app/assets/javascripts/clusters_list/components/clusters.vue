<script>
import {
  GlBadge,
  GlLink,
  GlLoadingIcon,
  GlPagination,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
  GlSprintf,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { __, sprintf } from '~/locale';
import { CLUSTER_TYPES, STATUSES } from '../constants';
import AncestorNotice from './ancestor_notice.vue';
import NodeErrorHelpText from './node_error_help_text.vue';

export default {
  nodeMemoryText: __('%{totalMemory} (%{freeSpacePercentage}%{percentSymbol} free)'),
  nodeCpuText: __('%{totalCpu} (%{freeSpacePercentage}%{percentSymbol} free)'),
  components: {
    AncestorNotice,
    GlBadge,
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlSkeletonLoading,
    GlSprintf,
    GlTable,
    NodeErrorHelpText,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState([
      'clusters',
      'clustersPerPage',
      'loadingClusters',
      'loadingNodes',
      'page',
      'providers',
      'totalCulsters',
    ]),
    contentAlignClasses() {
      return 'gl-display-flex gl-align-items-center gl-justify-content-end gl-justify-content-md-start';
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
        {
          key: 'total_cpu',
          label: __('Total cores (CPUs)'),
        },
        {
          key: 'total_memory',
          label: __('Total memory (GB)'),
        },
        {
          key: 'cluster_type',
          label: __('Cluster level'),
          formatter: (value) => CLUSTER_TYPES[value],
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
    ...mapActions(['fetchClusters', 'reportSentryError', 'setPage']),
    k8sQuantityToGb(quantity) {
      if (!quantity) {
        return 0;
      } else if (quantity.endsWith(__('Ki'))) {
        return parseInt(quantity.substr(0, quantity.length - 2), 10) * 0.000001024;
      } else if (quantity.endsWith(__('Mi'))) {
        return parseInt(quantity.substr(0, quantity.length - 2), 10) * 0.001048576;
      }

      // We are trying to track quantity types coming from Kubernetes.
      // Sentry will notify us if we are missing types.
      throw new Error(`UnknownK8sMemoryQuantity:${quantity}`);
    },
    k8sQuantityToCpu(quantity) {
      if (!quantity) {
        return 0;
      } else if (quantity.endsWith('m')) {
        return parseInt(quantity.substr(0, quantity.length - 1), 10) / 1000.0;
      } else if (quantity.endsWith('n')) {
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
  <gl-loading-icon v-if="loadingClusters" size="md" class="gl-mt-3" />

  <section v-else>
    <ancestor-notice />

    <gl-table
      :items="clusters"
      :fields="fields"
      stacked="md"
      class="qa-clusters-table"
      data-testid="cluster_list_table"
    >
      <template #cell(name)="{ item }">
        <div :class="[contentAlignClasses, 'js-status']">
          <img
            :src="selectedProvider(item.provider_type).path"
            :alt="selectedProvider(item.provider_type).text"
            class="gl-w-6 gl-h-6 gl-display-flex gl-align-items-center"
          />

          <gl-link
            data-qa-selector="cluster"
            :data-qa-cluster-name="item.name"
            :href="item.path"
            class="gl-px-3"
          >
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

        <gl-skeleton-loading v-else-if="loadingNodes" :lines="1" :class="contentAlignClasses" />

        <NodeErrorHelpText
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

        <gl-skeleton-loading v-else-if="loadingNodes" :lines="1" :class="contentAlignClasses" />

        <NodeErrorHelpText
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

        <gl-skeleton-loading v-else-if="loadingNodes" :lines="1" :class="contentAlignClasses" />

        <NodeErrorHelpText
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
