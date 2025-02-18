<script>
import { GlAlert, GlButton, GlLink, GlSprintf, GlTable } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

const KEY_CLOUDSQL_POSTGRES = 'cloudsql-postgres';
const KEY_CLOUDSQL_MYSQL = 'cloudsql-mysql';
const KEY_CLOUDSQL_SQLSERVER = 'cloudsql-sqlserver';
const KEY_ALLOYDB_POSTGRES = 'alloydb-postgres';
const KEY_MEMORYSTORE_REDIS = 'memorystore-redis';
const KEY_FIRESTORE = 'firestore';

const i18n = {
  columnService: s__('CloudSeed|Service'),
  columnDescription: s__('CloudSeed|Description'),
  cloudsqlPostgresTitle: s__('CloudSeed|Cloud SQL for Postgres'),
  cloudsqlPostgresDescription: s__(
    'CloudSeed|Fully managed relational database service for PostgreSQL',
  ),
  cloudsqlMysqlTitle: s__('CloudSeed|Cloud SQL for MySQL'),
  cloudsqlMysqlDescription: s__('CloudSeed|Fully managed relational database service for MySQL'),
  cloudsqlSqlserverTitle: s__('CloudSeed|Cloud SQL for SQL Server'),
  cloudsqlSqlserverDescription: s__(
    'CloudSeed|Fully managed relational database service for SQL Server',
  ),
  alloydbPostgresTitle: s__('CloudSeed|AlloyDB for Postgres'),
  alloydbPostgresDescription: s__(
    'CloudSeed|Fully managed PostgreSQL-compatible service for high-demand workloads',
  ),
  memorystoreRedisTitle: s__('CloudSeed|Memorystore for Redis'),
  memorystoreRedisDescription: s__(
    'CloudSeed|Scalable, secure, and highly available in-memory service for Redis',
  ),
  firestoreTitle: s__('CloudSeed|Cloud Firestore'),
  firestoreDescription: s__(
    'CloudSeed|Flexible, scalable NoSQL cloud database for client- and server-side development',
  ),
  createInstance: s__('CloudSeed|Create instance'),
  createCluster: s__('CloudSeed|Create cluster'),
  createDatabase: s__('CloudSeed|Create database'),
  title: s__('CloudSeed|Services'),
  description: s__('CloudSeed|Available database services through which instances may be created'),
  pricingAlert: s__(
    'CloudSeed|Learn more about pricing for %{cloudsqlPricingStart}Cloud SQL%{cloudsqlPricingEnd}, %{alloydbPricingStart}Alloy DB%{alloydbPricingEnd}, %{memorystorePricingStart}Memorystore%{memorystorePricingEnd} and %{firestorePricingStart}Firestore%{firestorePricingEnd}.',
  ),
  secretManagersDescription: s__(
    'CloudSeed|Enhance security by storing database variables in secret managers - learn more about %{docLinkStart}secret management with GitLab%{docLinkEnd}',
  ),
};

const helpUrlSecrets = helpPagePath('ci/secrets/_index');

export default {
  components: { GlAlert, GlButton, GlLink, GlSprintf, GlTable },
  props: {
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
    alloydbPostgresUrl: {
      type: String,
      required: true,
    },
    memorystoreRedisUrl: {
      type: String,
      required: true,
    },
    firestoreUrl: {
      type: String,
      required: true,
    },
  },
  methods: {
    actionUrl(key) {
      switch (key) {
        case KEY_CLOUDSQL_POSTGRES:
          return this.cloudsqlPostgresUrl;
        case KEY_CLOUDSQL_MYSQL:
          return this.cloudsqlMysqlUrl;
        case KEY_CLOUDSQL_SQLSERVER:
          return this.cloudsqlSqlserverUrl;
        case KEY_ALLOYDB_POSTGRES:
          return this.alloydbPostgresUrl;
        case KEY_MEMORYSTORE_REDIS:
          return this.memorystoreRedisUrl;
        case KEY_FIRESTORE:
          return this.firestoreUrl;
        default:
          return '#';
      }
    },
  },
  fields: [
    { key: 'title', label: i18n.columnService },
    { key: 'description', label: i18n.columnDescription },
    { key: 'action', label: '' },
  ],
  items: [
    {
      title: i18n.cloudsqlPostgresTitle,
      description: i18n.cloudsqlPostgresDescription,
      action: {
        key: KEY_CLOUDSQL_POSTGRES,
        title: i18n.createInstance,
        testId: 'button-cloudsql-postgres',
      },
    },
    {
      title: i18n.cloudsqlMysqlTitle,
      description: i18n.cloudsqlMysqlDescription,
      action: {
        disabled: false,
        key: KEY_CLOUDSQL_MYSQL,
        title: i18n.createInstance,
        testId: 'button-cloudsql-mysql',
      },
    },
    {
      title: i18n.cloudsqlSqlserverTitle,
      description: i18n.cloudsqlSqlserverDescription,
      action: {
        disabled: false,
        key: KEY_CLOUDSQL_SQLSERVER,
        title: i18n.createInstance,
        testId: 'button-cloudsql-sqlserver',
      },
    },
    {
      title: i18n.alloydbPostgresTitle,
      description: i18n.alloydbPostgresDescription,
      action: {
        disabled: true,
        key: KEY_ALLOYDB_POSTGRES,
        title: i18n.createCluster,
        testId: 'button-alloydb-postgres',
      },
    },
    {
      title: i18n.memorystoreRedisTitle,
      description: i18n.memorystoreRedisDescription,
      action: {
        disabled: true,
        key: KEY_MEMORYSTORE_REDIS,
        title: i18n.createInstance,
        testId: 'button-memorystore-redis',
      },
    },
    {
      title: i18n.firestoreTitle,
      description: i18n.firestoreDescription,
      action: {
        disabled: true,
        key: KEY_FIRESTORE,
        title: i18n.createDatabase,
        testId: 'button-firestore',
      },
    },
  ],
  helpUrlSecrets,
  i18n,
};
</script>

<template>
  <div class="gl-mx-3">
    <h2 class="gl-text-size-h2">{{ $options.i18n.title }}</h2>
    <p>{{ $options.i18n.description }}</p>

    <gl-table :fields="$options.fields" :items="$options.items">
      <template #cell(action)="{ value }">
        <gl-button
          block
          :disabled="value.disabled"
          :href="actionUrl(value.key)"
          :data-testid="value.testId"
          category="secondary"
          variant="confirm"
        >
          {{ value.title }}
        </gl-button>
      </template>
    </gl-table>

    <gl-alert class="gl-mt-5" :dismissible="false" variant="tip">
      <gl-sprintf :message="$options.i18n.pricingAlert">
        <template #cloudsqlPricing="{ content }">
          <gl-link href="https://cloud.google.com/sql/pricing">{{ content }}</gl-link>
        </template>
        <template #alloydbPricing="{ content }">
          <gl-link href="https://cloud.google.com/alloydb/pricing">{{ content }}</gl-link>
        </template>
        <template #memorystorePricing="{ content }">
          <gl-link href="https://cloud.google.com/memorystore/docs/redis/pricing">{{
            content
          }}</gl-link>
        </template>
        <template #firestorePricing="{ content }">
          <gl-link href="https://cloud.google.com/firestore/pricing">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-alert class="gl-mt-5" :dismissible="false" variant="tip">
      <gl-sprintf :message="$options.i18n.secretManagersDescription">
        <template #docLink="{ content }">
          <gl-link :href="$options.helpUrlSecrets">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
