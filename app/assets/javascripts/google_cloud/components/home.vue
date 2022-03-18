<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import DeploymentsServiceTable from './deployments_service_table.vue';
import RevokeOauth from './revoke_oauth.vue';
import ServiceAccountsList from './service_accounts_list.vue';
import GcpRegionsList from './gcp_regions_list.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    DeploymentsServiceTable,
    RevokeOauth,
    ServiceAccountsList,
    GcpRegionsList,
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
    configureGcpRegionsUrl: {
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
    gcpRegions: {
      type: Array,
      required: true,
    },
    revokeOauthUrl: {
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
      <hr />
      <gcp-regions-list
        class="gl-mx-4"
        :empty-illustration-url="emptyIllustrationUrl"
        :create-url="configureGcpRegionsUrl"
        :list="gcpRegions"
      />
      <hr v-if="revokeOauthUrl" />
      <revoke-oauth v-if="revokeOauthUrl" :url="revokeOauthUrl" />
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
