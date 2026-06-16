<script>
import { GlAlert, GlCard, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import DbSchemasSection from './db_schemas_section.vue';

export default {
  name: 'DbInformationCard',
  components: { GlAlert, GlCard, GlSprintf, DbSchemasSection },
  props: {
    dbName: {
      type: String,
      required: true,
    },
    payload: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    header: s__('DatabaseDiagnostics|Database: %{name}'),
  },
};
</script>

<template>
  <div class="gl-mb-6" :data-testid="`database-${dbName}`">
    <gl-card class="gl-w-full">
      <template #header>
        <h3 class="gl-heading-5 !gl-mb-0">
          <gl-sprintf :message="$options.i18n.header">
            <template #name>{{ dbName }}</template>
          </gl-sprintf>
        </h3>
      </template>

      <gl-alert v-if="payload.error" variant="warning" :dismissible="false">
        {{ payload.error }}
      </gl-alert>
      <db-schemas-section
        v-else
        :current-user="payload.current_user"
        :search-path="payload.search_path"
        :schemas="payload.schemas"
      />
    </gl-card>
  </div>
</template>
