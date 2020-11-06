<script>
import {
  GlButtonGroup,
  GlButton,
  GlIcon,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTable,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { trackAlertIntegrationsViewsOptions, integrationToDeleteDefault } from '../constants';

export const i18n = {
  title: s__('AlertsIntegrations|Current integrations'),
  emptyState: s__('AlertsIntegrations|No integrations have been added yet'),
  status: {
    enabled: {
      name: __('Enabled'),
      tooltip: s__('AlertsIntegrations|Alerts will be created through this integration'),
    },
    disabled: {
      name: __('Disabled'),
      tooltip: s__('AlertsIntegrations|Alerts will not be created through this integration'),
    },
  },
};

const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-b-solid gl-border-gray-100 gl-hover-cursor-pointer gl-hover-bg-blue-50 gl-hover-border-blue-200';

export default {
  i18n,
  components: {
    GlButtonGroup,
    GlButton,
    GlIcon,
    GlLoadingIcon,
    GlModal,
    GlTable,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    integrations: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  fields: [
    {
      key: 'active',
      label: __('Status'),
    },
    {
      key: 'name',
      label: s__('AlertsIntegrations|Integration Name'),
    },
    {
      key: 'type',
      label: __('Type'),
    },
    {
      key: 'actions',
      label: __('Actions'),
    },
  ],
  data() {
    return {
      integrationToDelete: integrationToDeleteDefault,
    };
  },
  computed: {
    tbodyTrClass() {
      return {
        [bodyTrClass]: this.integrations.length,
      };
    },
  },
  mounted() {
    this.trackPageViews();
  },
  methods: {
    trackPageViews() {
      const { category, action } = trackAlertIntegrationsViewsOptions;
      Tracking.event(category, action);
    },
    intergrationToDelete({ name, id }) {
      this.integrationToDelete.id = id;
      this.integrationToDelete.name = name;
    },
    deleteIntergration() {
      this.$emit('delete-integration', { id: this.integrationToDelete.id });
      this.integrationToDelete = { ...integrationToDeleteDefault };
    },
  },
};
</script>

<template>
  <div class="incident-management-list">
    <h5 class="gl-font-lg">{{ $options.i18n.title }}</h5>
    <gl-table
      :items="integrations"
      :fields="$options.fields"
      :busy="loading"
      stacked="md"
      :tbody-tr-class="tbodyTrClass"
      show-empty
    >
      <template #cell(active)="{ item }">
        <span v-if="item.active" data-testid="integration-activated-status">
          <gl-icon
            v-gl-tooltip
            name="check-circle-filled"
            :size="16"
            class="gl-text-green-500 gl-hover-cursor-pointer gl-mr-3"
            :title="$options.i18n.status.enabled.tooltip"
          />
          {{ $options.i18n.status.enabled.name }}
        </span>
        <span v-else data-testid="integration-activated-status">
          <gl-icon
            v-gl-tooltip
            name="warning-solid"
            :size="16"
            class="gl-text-red-600 gl-hover-cursor-pointer gl-mr-3"
            :title="$options.i18n.status.disabled.tooltip"
          />
          {{ $options.i18n.status.disabled.name }}
        </span>
      </template>

      <template #cell(actions)="{ item }">
        <gl-button-group>
          <gl-button icon="pencil" @click="$emit('edit-integration', { id: item.id })" />
          <gl-button
            v-gl-modal.deleteIntegration
            icon="remove"
            @click="intergrationToDelete(item)"
          />
        </gl-button-group>
      </template>

      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="mt-3" />
      </template>

      <template #empty>
        <div
          class="gl-border-t-solid gl-border-b-solid gl-border-1 gl-border gl-border-gray-100 mt-n3"
        >
          <p class="gl-text-gray-400 gl-py-3 gl-my-3">{{ $options.i18n.emptyState }}</p>
        </div>
      </template>
    </gl-table>
    <gl-modal
      modal-id="deleteIntegration"
      :title="__('Are you sure?')"
      :ok-title="s__('AlertSettings|Delete integration')"
      ok-variant="danger"
      @ok="deleteIntergration"
    >
      <gl-sprintf
        :message="
          s__(
            'AlertsIntegrations|You have opted to delete the %{integrationName} integration. Do you want to proceed? It means you will no longer receive alerts from this endpoint in your alert list, and this action cannot be undone.',
          )
        "
      >
        <template #integrationName>{{ integrationToDelete.name }}</template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
