<!-- eslint-disable vue/multi-word-component-names -->
<script>
import GoogleCloudMenu from '../components/google_cloud_menu.vue';
import IncubationBanner from '../components/incubation_banner.vue';
import ServiceTable from './service_table.vue';

export default {
  components: {
    ServiceTable,
    IncubationBanner,
    GoogleCloudMenu,
  },
  props: {
    configurationUrl: {
      type: String,
      required: true,
    },
    deploymentsUrl: {
      type: String,
      required: true,
    },
    databasesUrl: {
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
  <div>
    <incubation-banner />

    <google-cloud-menu
      active="deployments"
      :configuration-url="configurationUrl"
      :deployments-url="deploymentsUrl"
      :databases-url="databasesUrl"
    />

    <service-table :cloud-run-url="enableCloudRunUrl" :cloud-storage-url="enableCloudStorageUrl" />
  </div>
</template>
