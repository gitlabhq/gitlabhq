<script>
import { GlTable } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export const i18n = {
  title: s__('AlertsIntegrations|Current integrations'),
  emptyState: s__('AlertsIntegrations|No integrations have been added yet'),
  status: {
    enabled: __('Enabled'),
    disabled: __('Disabled'),
  },
};

const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-b-solid gl-border-gray-100 gl-hover-cursor-pointer gl-hover-bg-blue-50 gl-hover-border-blue-200';

export default {
  i18n,
  components: {
    GlTable,
  },
  props: {
    integrations: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  fields: [
    {
      key: 'status',
      label: __('Status'),
      formatter(enabled) {
        return enabled ? i18n.status.enabled : i18n.status.disabled;
      },
    },
    {
      key: 'name',
      label: s__('AlertsIntegrations|Integration Name'),
    },
    {
      key: 'type',
      label: __('Type'),
    },
  ],
  computed: {
    tbodyTrClass() {
      return {
        [bodyTrClass]: this.integrations.length,
      };
    },
  },
};
</script>

<template>
  <div class="incident-management-list">
    <h5 class="gl-font-lg">{{ $options.i18n.title }}</h5>
    <gl-table
      :empty-text="$options.i18n.emptyState"
      :items="integrations"
      :fields="$options.fields"
      stacked="md"
      :tbody-tr-class="tbodyTrClass"
      show-empty
    />
  </div>
</template>
