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

export default {
  i18n,
  typeSet,
  modal: {
    actionPrimary: {
      text: i18n.deleteIntegration,
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
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
      tdClass: '!gl-align-middle',
    },
    {
      key: 'name',
      label: s__('AlertsIntegrations|Integration Name'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'type',
      label: __('Type'),
      tdClass: '!gl-align-middle',
      formatter: (value) => (value === typeSet.prometheus ? capitalize(value) : value),
    },
    {
      key: 'actions',
      thAlignRight: true,
      tdClass: 'gl-text-right !gl-align-middle',
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
  <div class="paginated-table-wrapper">
    <gl-table
      class="integration-list"
      :items="integrations"
      :fields="$options.fields"
      :busy="loading"
      stacked="md"
      show-empty
    >
      <template #cell(active)="{ item }">
        <span v-if="item.active" data-testid="integration-activated-status">
          <gl-icon
            v-gl-tooltip
            name="check"
            :size="16"
            class="gl-mr-3 hover:gl-cursor-pointer"
            :title="$options.i18n.status.enabled.tooltip"
            variant="success"
          />
          {{ $options.i18n.status.enabled.name }}
        </span>
        <span v-else data-testid="integration-activated-status">
          <gl-icon
            v-gl-tooltip
            name="warning-solid"
            :size="16"
            class="gl-mr-3 gl-text-danger hover:gl-cursor-pointer"
            :title="$options.i18n.status.disabled.tooltip"
            variant="danger"
          />
          {{ $options.i18n.status.disabled.name }}
        </span>
      </template>

      <template #cell(actions)="{ item }">
        <gl-button-group class="-gl-mb-2 -gl-mt-2 gl-ml-3">
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
        <gl-loading-icon size="sm" />
      </template>

      <template #empty>
        <p class="gl-mb-0 gl-text-subtle">{{ $options.i18n.emptyState }}</p>
      </template>
    </gl-table>

    <gl-modal
      modal-id="deleteIntegration"
      :title="$options.i18n.deleteIntegration"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
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
