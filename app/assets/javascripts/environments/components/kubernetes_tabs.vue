<script>
import { GlTabs, GlTab, GlLoadingIcon, GlBadge, GlTable, GlPagination } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import {
  getAge,
  generateServicePortsString,
} from '~/kubernetes_dashboard/helpers/k8s_integration_helper';
import { SERVICES_TABLE_FIELDS } from '~/kubernetes_dashboard/constants';
import k8sServicesQuery from '../graphql/queries/k8s_services.query.graphql';
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
          namespace: this.namespace,
        };
      },
      update(data) {
        return data?.k8sServices || [];
      },
      error(error) {
        this.$emit('cluster-error', error.message);
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
          age: getAge(service?.metadata?.creationTimestamp),
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
    servicesFields() {
      return SERVICES_TABLE_FIELDS.map((field) => {
        return {
          ...field,
          thClass: tableHeadingClasses,
        };
      });
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
        :fields="servicesFields"
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
