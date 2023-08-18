<script>
import { GlCard } from '@gitlab/ui';
import { s__ } from '~/locale';
import IntegrationsTable from './integrations_table.vue';

export default {
  name: 'IntegrationsList',
  components: {
    IntegrationsTable,
    GlCard,
  },
  props: {
    integrations: {
      type: Array,
      required: true,
    },
  },
  computed: {
    integrationsGrouped() {
      return this.integrations.reduce(
        (integrations, integration) => {
          if (integration.active) {
            integrations.active.push(integration);
          } else {
            integrations.inactive.push(integration);
          }

          return integrations;
        },
        { active: [], inactive: [] },
      );
    },
  },
  i18n: {
    activeTableEmptyText: s__("Integrations|You haven't activated any integrations yet."),
    inactiveTableEmptyText: s__("Integrations|You've activated every integration 🎉"),
    activeIntegrationsHeading: s__('Integrations|Active integrations'),
    inactiveIntegrationsHeading: s__('Integrations|Add an integration'),
  },
};
</script>

<template>
  <div>
    <gl-card
      class="gl-new-card gl-overflow-hidden"
      header-class="gl-new-card-header gl-border-b-0"
      body-class="gl-new-card-body gl-px-0"
    >
      <template #header>
        <h3 class="gl-new-card-title">{{ $options.i18n.activeIntegrationsHeading }}</h3>
      </template>
      <integrations-table
        class="gl-mb-n2"
        :integrations="integrationsGrouped.active"
        :empty-text="$options.i18n.activeTableEmptyText"
        show-updated-at
        data-testid="active-integrations-table"
      />
    </gl-card>
    <gl-card
      class="gl-new-card gl-overflow-hidden"
      header-class="gl-new-card-header gl-border-b-0"
      body-class="gl-new-card-body gl-px-0"
    >
      <template #header>
        <h3 class="gl-new-card-title">{{ $options.i18n.inactiveIntegrationsHeading }}</h3>
      </template>
      <integrations-table
        class="gl-mb-n2"
        inactive
        :integrations="integrationsGrouped.inactive"
        :empty-text="$options.i18n.inactiveTableEmptyText"
        data-testid="inactive-integrations-table"
      />
    </gl-card>
  </div>
</template>
