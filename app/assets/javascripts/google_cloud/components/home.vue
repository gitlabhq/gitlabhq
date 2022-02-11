<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import DeploymentsServiceTable from './deployments_service_table.vue';
import ServiceAccountsList from './service_accounts_list.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    DeploymentsServiceTable,
    ServiceAccountsList,
  },
  props: {
    serviceAccounts: {
      type: Array,
      required: true,
    },
    createServiceAccountUrl: {
      type: String,
      required: true,
    },
    emptyIllustrationUrl: {
      type: String,
      required: true,
    },
    enableCloudRunUrl: {
      type: String,
      required: true,
    },
    enableCloudStorageUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab :title="__('Configuration')">
      <service-accounts-list
        class="gl-mx-4"
        :list="serviceAccounts"
        :create-url="createServiceAccountUrl"
        :empty-illustration-url="emptyIllustrationUrl"
      />
    </gl-tab>
    <gl-tab :title="__('Deployments')">
      <deployments-service-table
        :cloud-run-url="enableCloudRunUrl"
        :cloud-storage-url="enableCloudStorageUrl"
      />
    </gl-tab>
    <gl-tab :title="__('Services')" disabled />
  </gl-tabs>
</template>
