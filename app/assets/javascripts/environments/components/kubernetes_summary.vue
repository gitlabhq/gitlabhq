<script>
import { GlTab, GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import k8sWorkloadsQuery from '../graphql/queries/k8s_workloads.query.graphql';
import {
  getDeploymentsStatuses,
  getDaemonSetStatuses,
  getStatefulSetStatuses,
  getReplicaSetStatuses,
  getJobsStatuses,
  getCronJobsStatuses,
} from '../helpers/k8s_integration_helper';

export default {
  components: {
    GlTab,
    GlBadge,
    GlLoadingIcon,
  },
  apollo: {
    k8sWorkloads: {
      query: k8sWorkloadsQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      update(data) {
        return data?.k8sWorkloads || {};
      },
      error(error) {
        this.$emit('cluster-error', error);
      },
    },
  },
  props: {
    configuration: {
      required: true,
      type: Object,
    },
    namespace: {
      required: true,
      type: String,
    },
  },
  computed: {
    summaryLoading() {
      return this.$apollo.queries.k8sWorkloads.loading;
    },
    summaryCount() {
      return this.k8sWorkloads ? Object.values(this.k8sWorkloads).flat().length : 0;
    },
    summaryObjects() {
      return [
        this.deploymentsItems,
        this.daemonSetsItems,
        this.statefulSetItems,
        this.replicaSetItems,
        this.jobItems,
        this.cronJobItems,
      ].filter(Boolean);
    },
    deploymentsItems() {
      const items = this.k8sWorkloads?.DeploymentList;
      if (!items?.length) {
        return null;
      }

      return {
        name: this.$options.i18n.deployments,
        items: getDeploymentsStatuses(items),
      };
    },
    daemonSetsItems() {
      const items = this.k8sWorkloads?.DaemonSetList;
      if (!items?.length) {
        return null;
      }

      return {
        name: this.$options.i18n.daemonSets,
        items: getDaemonSetStatuses(items),
      };
    },
    statefulSetItems() {
      const items = this.k8sWorkloads?.StatefulSetList;
      if (!items?.length) {
        return null;
      }

      return {
        name: this.$options.i18n.statefulSets,
        items: getStatefulSetStatuses(items),
      };
    },
    replicaSetItems() {
      const items = this.k8sWorkloads?.ReplicaSetList;
      if (!items?.length) {
        return null;
      }

      return {
        name: this.$options.i18n.replicaSets,
        items: getReplicaSetStatuses(items),
      };
    },
    jobItems() {
      const items = this.k8sWorkloads?.JobList;
      if (!items?.length) {
        return null;
      }

      return {
        name: this.$options.i18n.jobs,
        items: getJobsStatuses(items),
      };
    },
    cronJobItems() {
      const items = this.k8sWorkloads?.CronJobList;
      if (!items?.length) {
        return null;
      }

      return {
        name: this.$options.i18n.cronJobs,
        items: getCronJobsStatuses(items),
      };
    },
  },
  i18n: {
    summaryTitle: s__('Environment|Summary'),
    deployments: s__('Environment|Deployments'),
    daemonSets: s__('Environment|DaemonSets'),
    statefulSets: s__('Environment|StatefulSets'),
    replicaSets: s__('Environment|ReplicaSets'),
    jobs: s__('Environment|Jobs'),
    cronJobs: s__('Environment|CronJobs'),
  },
  badgeVariants: {
    ready: 'success',
    completed: 'success',
    failed: 'danger',
    suspended: 'neutral',
  },
  icons: {
    Active: { icon: 'status_success', class: 'gl-text-green-500' },
  },
};
</script>
<template>
  <gl-tab>
    <template #title>
      {{ $options.i18n.summaryTitle }}
      <gl-badge size="sm" class="gl-tab-counter-badge">{{ summaryCount }}</gl-badge>
    </template>

    <gl-loading-icon v-if="summaryLoading" />

    <ul v-else class="gl-mt-3 gl-list-style-none gl-bg-white gl-pl-0 gl-mb-0">
      <li
        v-for="object in summaryObjects"
        :key="object.name"
        class="gl-display-flex gl-align-items-center gl-p-3 gl-border-t gl-text-gray-700"
        data-testid="summary-list-item"
      >
        <div class="gl-flex-grow-1">{{ object.name }}</div>

        <gl-badge
          v-for="(item, key) in object.items"
          :key="key"
          :variant="$options.badgeVariants[key]"
          size="sm"
          class="gl-ml-2"
          >{{ item.length }} {{ key }}</gl-badge
        >
      </li>
    </ul>
  </gl-tab>
</template>
