<!-- eslint-disable vue/multi-word-component-names -->
<script>
import GoogleCloudMenu from '../components/google_cloud_menu.vue';
import IncubationBanner from '../components/incubation_banner.vue';
import InstanceTable from './cloudsql/instance_table.vue';
import ServiceTable from './service_table.vue';

export default {
  components: {
    IncubationBanner,
    InstanceTable,
    GoogleCloudMenu,
    ServiceTable,
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
    cloudsqlPostgresUrl: {
      type: String,
      required: true,
    },
    cloudsqlMysqlUrl: {
      type: String,
      required: true,
    },
    cloudsqlSqlserverUrl: {
      type: String,
      required: true,
    },
    cloudsqlInstances: {
      type: Array,
      required: true,
    },
    emptyIllustrationUrl: {
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
      active="databases"
      :configuration-url="configurationUrl"
      :deployments-url="deploymentsUrl"
      :databases-url="databasesUrl"
    />

    <service-table
      alloydb-postgres-url="#"
      :cloudsql-mysql-url="cloudsqlMysqlUrl"
      :cloudsql-postgres-url="cloudsqlPostgresUrl"
      :cloudsql-sqlserver-url="cloudsqlSqlserverUrl"
      firestore-url="#"
      memorystore-redis-url="#"
    />

    <instance-table
      :cloudsql-instances="cloudsqlInstances"
      :empty-illustration-url="emptyIllustrationUrl"
    />
  </div>
</template>
