<script>
import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlButton,
  GlIcon,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlButton,
    GlIcon,
    GlTable,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    integrations: {
      type: Array,
      required: true,
    },
    showUpdatedAt: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyText: {
      type: String,
      required: false,
      default: undefined,
    },
    inactive: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    fields() {
      if (this.filteredIntegrations.length === 0) {
        return [];
      }

      const fields = [];

      fields.push(
        {
          key: 'active',
          label: '',
          thClass: 'gl-w-7',
          tdClass: '!gl-border-b-0 !gl-align-middle',
        },
        {
          key: 'title',
          label: __('Integration'),
          thClass: 'd-sm-table-cell',
          tdClass: '!gl-border-b-0',
        },
      );

      if (!this.inactive && this.filteredIntegrations.length > 0) {
        fields.push({
          key: 'updated_at',
          label: this.showUpdatedAt ? __('Last updated') : '',
          thAlignRight: true,
          thClass: 'gl-hidden d-sm-table-cell',
          tdClass: '!gl-border-b-0 gl-text-right gl-hidden d-sm-table-cell !gl-align-middle',
        });
      }

      fields.push({
        key: 'edit_path',
        label: '',
        thClass: 'gl-w-15',
        tdClass: '!gl-border-b-0',
      });

      return fields;
    },
    filteredIntegrations() {
      return this.integrations.filter(
        (integration) =>
          !(integration.name === 'prometheus' && this.glFeatures.removeMonitorMetrics),
      );
    },
  },
  methods: {
    getStatusTooltipTitle(integration) {
      const status = integration.active ? 'active' : 'inactive';

      return sprintf(s__('Integrations|%{integrationTitle}: %{status}'), {
        integrationTitle: integration.title,
        status,
      });
    },
  },
};
</script>

<template>
  <gl-table
    :items="filteredIntegrations"
    :fields="fields"
    :empty-text="emptyText"
    show-empty
    fixed
    class="gl-mb-0"
  >
    <template #cell(active)="{ item }">
      <gl-icon
        v-if="item.configured"
        v-gl-tooltip
        :name="item.active ? 'status-success' : 'status-paused'"
        :class="item.active ? 'gl-text-green-500' : 'gl-text-gray-500'"
        :title="getStatusTooltipTitle(item)"
      />
    </template>

    <template #cell(title)="{ item }">
      <gl-avatar-link :href="item.edit_path" :title="item.title" :data-testid="`${item.name}-link`">
        <gl-avatar-labeled
          :label="item.title"
          :sub-label="item.description"
          :entity-id="item.id"
          :entity-name="item.title"
          :src="item.icon"
          :size="32"
          shape="rect"
          :label-link="item.edit_path"
        />
      </gl-avatar-link>
    </template>

    <template #cell(updated_at)="{ item }">
      <time-ago-tooltip v-if="showUpdatedAt && item.updated_at" :time="item.updated_at" />
    </template>

    <template #cell(edit_path)="{ item }">
      <gl-button :href="item.edit_path">
        {{ __('Configure') }}
      </gl-button>
    </template>
  </gl-table>
</template>
