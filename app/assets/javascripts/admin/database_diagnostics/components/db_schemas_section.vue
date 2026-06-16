<script>
import { GlBadge, GlIcon, GlTableLite } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'DbSchemasSection',
  components: { GlBadge, GlIcon, GlTableLite },
  props: {
    currentUser: {
      type: String,
      required: true,
    },
    searchPath: {
      type: String,
      required: true,
    },
    schemas: {
      type: Array,
      required: true,
    },
  },
  fields: [
    { key: 'name', label: s__('DatabaseDiagnostics|Schema') },
    { key: 'owner', label: s__('DatabaseDiagnostics|Owner') },
  ],
  i18n: {
    title: s__('DatabaseDiagnostics|Schemas'),
    currentUserLabel: s__('DatabaseDiagnostics|Current user:'),
    searchPathLabel: s__('DatabaseDiagnostics|Search path:'),
    currentBadge: s__('DatabaseDiagnostics|Current'),
  },
};
</script>

<template>
  <section>
    <h4 class="gl-heading-5 gl-flex gl-items-center gl-gap-3">
      <gl-icon name="information-o" variant="info" />
      {{ $options.i18n.title }}
    </h4>

    <p class="gl-text-sm gl-text-subtle">
      <span data-testid="current-user">
        <strong>{{ $options.i18n.currentUserLabel }}</strong>
        <code>{{ currentUser }}</code>
      </span>
      <span class="gl-ml-3" data-testid="search-path">
        <strong>{{ $options.i18n.searchPathLabel }}</strong>
        <code>{{ searchPath }}</code>
      </span>
    </p>

    <gl-table-lite
      :items="schemas"
      :fields="$options.fields"
      stacked="md"
      data-testid="schemas-table"
    >
      <template #cell(name)="{ item }">
        {{ item.name }}
        <gl-badge v-if="item.current" variant="info" class="gl-ml-2">
          {{ $options.i18n.currentBadge }}
        </gl-badge>
      </template>
    </gl-table-lite>
  </section>
</template>
