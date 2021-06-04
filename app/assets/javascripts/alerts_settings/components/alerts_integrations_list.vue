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
import { capitalize } from 'lodash';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import {
  trackAlertIntegrationsViewsOptions,
  integrationToDeleteDefault,
  typeSet,
} from '../constants';
import getCurrentIntegrationQuery from '../graphql/queries/get_current_integration.query.graphql';

export const i18n = {
  deleteIntegration: s__('AlertSettings|Delete integration'),
  editIntegration: s__('AlertSettings|Edit integration'),
  emptyState: s__('AlertsIntegrations|No integrations have been added yet.'),
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
  typeSet,
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
      formatter: (value) => (value === typeSet.prometheus ? capitalize(value) : value),
    },
    {
      key: 'actions',
      thClass: `gl-text-center`,
      tdClass: `gl-text-center`,
      label: __('Actions'),
    },
  ],
  apollo: {
    currentIntegration: {
      query: getCurrentIntegrationQuery,
    },
  },
  data() {
    return {
      integrationToDelete: integrationToDeleteDefault,
      currentIntegration: null,
    };
  },
  mounted() {
    const callback = (entries) => {
      const isVisible = entries.some((entry) => entry.isIntersecting);

      if (isVisible) {
        this.trackPageViews();
        this.observer.disconnect();
      }
    };

    this.observer = new IntersectionObserver(callback);
    this.observer.observe(this.$el);
  },
  methods: {
    tbodyTrClass(item) {
      return {
        [bodyTrClass]: this.integrations?.length,
        'gl-bg-blue-50': (item !== null && item.id) === this.currentIntegration?.id,
      };
    },
    trackPageViews() {
      const { category, action } = trackAlertIntegrationsViewsOptions;
      Tracking.event(category, action);
    },
    setIntegrationToDelete(integration) {
      this.integrationToDelete = integration;
    },
    deleteIntegration() {
      const { id, type } = this.integrationToDelete;
      this.$emit('delete-integration', { id, type });
      this.integrationToDelete = { ...integrationToDeleteDefault };
    },
    editIntegration({ id, type }) {
      this.$emit('edit-integration', { id, type });
    },
  },
};
</script>

<template>
  <div class="incident-management-list">
    <gl-table
      class="integration-list"
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
            name="check"
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
        <gl-button-group class="gl-ml-3">
          <gl-button
            icon="settings"
            :aria-label="$options.i18n.editIntegration"
            @click="editIntegration(item)"
          />
          <gl-button
            v-gl-modal.deleteIntegration
            :disabled="item.type === $options.typeSet.prometheus"
            icon="remove"
            :aria-label="$options.i18n.deleteIntegration"
            @click="setIntegrationToDelete(item)"
          />
        </gl-button-group>
      </template>

      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="mt-3" />
      </template>

      <template #empty>
        <div
          class="gl-border-t-solid gl-border-b-solid gl-border-1 gl-border gl-border-gray-100 mt-n3 gl-px-5"
        >
          <p class="gl-text-gray-400 gl-py-3 gl-my-3">{{ $options.i18n.emptyState }}</p>
        </div>
      </template>
    </gl-table>
    <gl-modal
      modal-id="deleteIntegration"
      :title="$options.i18n.deleteIntegration"
      :ok-title="$options.i18n.deleteIntegration"
      ok-variant="danger"
      @ok="deleteIntegration"
    >
      <gl-sprintf
        :message="
          s__(
            'AlertsIntegrations|If you delete the %{integrationName} integration, alerts are no longer sent from this endpoint. This action cannot be undone.',
          )
        "
      >
        <template #integrationName>{{ integrationToDelete.name }}</template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
