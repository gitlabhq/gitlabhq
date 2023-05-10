<script>
import { GlIcon, GlLink, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlIcon,
    GlLink,
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
  },
  computed: {
    fields() {
      return [
        {
          key: 'active',
          label: '',
          thClass: 'gl-w-10',
        },
        {
          key: 'title',
          label: __('Integration'),
          thClass: 'gl-w-quarter',
        },
        {
          key: 'description',
          label: __('Description'),
          thClass: 'gl-display-none d-sm-table-cell',
          tdClass: 'gl-display-none d-sm-table-cell',
        },
        {
          key: 'updated_at',
          label: this.showUpdatedAt ? __('Last updated') : '',
          thClass: 'gl-w-20p',
        },
      ];
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
      return sprintf(s__('Integrations|%{integrationTitle}: active'), {
        integrationTitle: integration.title,
      });
    },
  },
};
</script>

<template>
  <gl-table :items="filteredIntegrations" :fields="fields" :empty-text="emptyText" show-empty fixed>
    <template #cell(active)="{ item }">
      <gl-icon
        v-if="item.active"
        v-gl-tooltip
        name="check"
        class="gl-text-green-500"
        :title="getStatusTooltipTitle(item)"
      />
    </template>

    <template #cell(title)="{ item }">
      <gl-link
        :href="item.edit_path"
        class="gl-font-weight-bold"
        :data-qa-selector="`${item.name}_link`"
      >
        {{ item.title }}
      </gl-link>
    </template>

    <template #cell(updated_at)="{ item }">
      <time-ago-tooltip v-if="showUpdatedAt && item.updated_at" :time="item.updated_at" />
    </template>
  </gl-table>
</template>
