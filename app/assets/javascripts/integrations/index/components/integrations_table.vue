<script>
import { GlAvatar, GlAvatarLink, GlButton, GlIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlAvatar,
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
          tdClass: '!gl-border-b-0 !gl-align-middle',
        },
      );

      if (!this.inactive && this.filteredIntegrations.length > 0) {
        fields.push({
          key: 'updated_at',
          label: this.showUpdatedAt ? __('Last updated') : '',
          thAlignRight: true,
          thClass: 'gl-hidden d-sm-table-cell gl-w-20',
          tdClass: '!gl-border-b-0 gl-text-right gl-hidden d-sm-table-cell !gl-align-middle',
        });
      }

      fields.push({
        key: 'edit_path',
        label: '',
        thClass: 'gl-w-15',
        tdClass: '!gl-border-b-0 gl-text-right !gl-align-middle',
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
    navigateToItemSettings({ edit_path }) {
      return visitUrl(edit_path);
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
    hover
    class="gl-mb-0"
    tbody-tr-class="gl-cursor-pointer hover:!gl-bg-strong"
    @row-clicked="navigateToItemSettings"
  >
    <template #cell(active)="{ item }">
      <gl-icon
        v-if="item.configured"
        v-gl-tooltip
        :name="item.active ? 'status-success' : 'status-paused'"
        :variant="item.active ? 'success' : 'subtle'"
        :title="getStatusTooltipTitle(item)"
        data-testid="integration-active-icon"
      />
    </template>

    <template #cell(title)="{ item }">
      <gl-avatar-link
        tabindex="-1"
        :href="item.edit_path"
        :title="item.title"
        :data-testid="`${item.name}-link`"
        class="gl-items-center gl-gap-x-4"
      >
        <gl-avatar
          :src="item.icon"
          :entity-name="item.title"
          :alt="item.title"
          :size="48"
          shape="rect"
          class="integration-logo"
        />
        <div class="gl-flex gl-flex-col gl-gap-2">
          <h3 class="gl-heading-4 gl-my-1">{{ item.title }}</h3>
          <p class="gl-mb-0 gl-text-subtle">{{ item.description }}</p>
        </div>
      </gl-avatar-link>
    </template>

    <template #cell(updated_at)="{ item }">
      <time-ago-tooltip
        v-if="showUpdatedAt && item.updated_at"
        :time="item.updated_at"
        class="gl-text-subtle"
      />
    </template>

    <template #cell(edit_path)="{ item }">
      <gl-button
        v-if="inactive"
        v-gl-tooltip
        tabindex="-1"
        :href="item.edit_path"
        category="secondary"
        icon="plus"
        :title="s__('Integrations|Add integration')"
        >{{ __('Add') }}</gl-button
      >
      <gl-button
        v-else
        v-gl-tooltip
        tabindex="-1"
        :href="item.edit_path"
        category="secondary"
        icon="settings"
        :title="__('Configure')"
      />
    </template>
  </gl-table>
</template>
