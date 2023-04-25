<script>
import { GlTabs, GlTab, GlLoadingIcon, GlBadge, GlTable, GlPagination } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import k8sServicesQuery from '../graphql/queries/k8s_services.query.graphql';
import { generateServicePortsString, getServiceAge } from '../helpers/k8s_integration_helper';
import { SERVICES_LIMIT_PER_PAGE } from '../constants';

const tableHeadingClasses = 'gl-bg-gray-50! gl-font-weight-bold gl-white-space-nowrap';

export default {
  components: {
    GlTabs,
    GlTab,
    GlBadge,
    GlTable,
    GlPagination,
    GlLoadingIcon,
  },
  apollo: {
    k8sServices: {
      query: k8sServicesQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return data?.k8sServices || [];
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
  },
  data() {
    return {
      currentPage: 1,
    };
  },
  computed: {
    servicesItems() {
      if (!this.k8sServices?.length) return [];

      return this.k8sServices.map((service) => {
        return {
          name: service?.metadata?.name,
          namespace: service?.metadata?.namespace,
          type: service?.spec?.type,
          clusterIP: service?.spec?.clusterIP,
          externalIP: service?.spec?.externalIP,
          ports: generateServicePortsString(service?.spec?.ports),
          age: getServiceAge(service?.metadata?.creationTimestamp),
        };
      });
    },
    servicesLoading() {
      return this.$apollo.queries.k8sServices.loading;
    },
    showPagination() {
      return this.servicesItems.length > SERVICES_LIMIT_PER_PAGE;
    },
    prevPage() {
      return Math.max(this.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.currentPage + 1;
      return nextPage > Math.ceil(this.servicesItems.length / SERVICES_LIMIT_PER_PAGE)
        ? null
        : nextPage;
    },
  },
  i18n: {
    servicesTitle: s__('Environment|Services'),
    name: __('Name'),
    namespace: __('Namespace'),
    status: __('Status'),
    type: __('Type'),
    clusterIP: s__('Environment|Cluster IP'),
    externalIP: s__('Environment|External IP'),
    ports: s__('Environment|Ports'),
    age: s__('Environment|Age'),
  },
  servicesFields: [
    {
      key: 'name',
      label: __('Name'),
      thClass: tableHeadingClasses,
    },
    {
      key: 'namespace',
      label: __('Namespace'),
      thClass: tableHeadingClasses,
    },
    {
      key: 'type',
      label: __('Type'),
      thClass: tableHeadingClasses,
    },
    {
      key: 'clusterIP',
      label: s__('Environment|Cluster IP'),
      thClass: tableHeadingClasses,
    },
    {
      key: 'externalIP',
      label: s__('Environment|External IP'),
      thClass: tableHeadingClasses,
    },
    {
      key: 'ports',
      label: s__('Environment|Ports'),
      thClass: tableHeadingClasses,
    },
    {
      key: 'age',
      label: s__('Environment|Age'),
      thClass: tableHeadingClasses,
    },
  ],
  SERVICES_LIMIT_PER_PAGE,
};
</script>
<template>
  <gl-tabs>
    <gl-tab>
      <template #title>
        {{ $options.i18n.servicesTitle }}
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ servicesItems.length }}</gl-badge>
      </template>

      <gl-loading-icon v-if="servicesLoading" />

      <gl-table
        v-else
        :fields="$options.servicesFields"
        :items="servicesItems"
        :per-page="$options.SERVICES_LIMIT_PER_PAGE"
        :current-page="currentPage"
        stacked="lg"
        class="gl-bg-white! gl-mt-3"
      />
      <gl-pagination
        v-if="showPagination"
        v-model="currentPage"
        :prev-page="prevPage"
        :next-page="nextPage"
        align="center"
        class="gl-mt-6"
      />
    </gl-tab>
  </gl-tabs>
</template>
