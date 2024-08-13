<script>
import { s__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import IntegrationsTable from './integrations_table.vue';

export default {
  name: 'IntegrationsList',
  components: {
    IntegrationsTable,
    CrudComponent,
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
    <crud-component :title="$options.i18n.activeIntegrationsHeading" class="gl-mb-5">
      <integrations-table
        :integrations="integrationsGrouped.active"
        :empty-text="$options.i18n.activeTableEmptyText"
        show-updated-at
        data-testid="active-integrations-table"
      />
    </crud-component>
    <crud-component :title="$options.i18n.inactiveIntegrationsHeading">
      <integrations-table
        inactive
        :integrations="integrationsGrouped.inactive"
        :empty-text="$options.i18n.inactiveTableEmptyText"
        data-testid="inactive-integrations-table"
      />
    </crud-component>
  </div>
</template>
