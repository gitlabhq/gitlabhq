<script>
import { GlCard } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { getTimeago, timeagoLanguageCode } from '~/lib/utils/datetime_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DashboardsListItemActions from 'ee_else_ce/vue_shared/components/dashboards_list/dashboards_list_item_actions.vue';
import DashboardCardThumbnail from './dashboard_card_thumbnail.vue';
import DashboardsListAuthor from './dashboards_list_author.vue';
import DashboardsListNameCell from './dashboards_list_name_cell.vue';
import { configToPreviewPieces } from './dashboard_preview_layout';

export default {
  name: 'DashboardCard',
  components: {
    GlCard,
    DashboardCardThumbnail,
    DashboardsListAuthor,
    DashboardsListItemActions,
    DashboardsListNameCell,
    TimeAgoTooltip,
  },
  props: {
    dashboard: {
      type: Object,
      required: true,
      // Cheap explicit contract for the fields every card branch relies on.
      validator: ({ id, name, dashboardUrl, system }) =>
        Boolean(id && name && dashboardUrl) && typeof system === 'boolean',
    },
  },
  computed: {
    actionsLabel() {
      return sprintf(
        s__('AnalyticsDashboards|More actions for %{name}'),
        { name: this.dashboard.name },
        false,
      );
    },
    // The aria-label sentence for the timestamp; must format the time the same
    // way as the default-configured TimeAgoTooltip rendering the visible text.
    updatedLabel() {
      return sprintf(__('Updated %{timeAgo}'), {
        timeAgo: getTimeago().format(this.dashboard.updatedAt, timeagoLanguageCode),
      });
    },
    // Custom dashboards can have a null slug, so fall back to the id to keep
    // the generated thumbnail stable per dashboard.
    thumbnailSeedKey() {
      return String(this.dashboard.slug || this.dashboard.id || '');
    },
    // Pieces mimicking the dashboard's real panels; null (no usable config)
    // leaves the thumbnail purely seeded.
    thumbnailPieces() {
      return configToPreviewPieces(this.dashboard.config);
    },
  },
};
</script>
<template>
  <li class="gl-relative gl-flex" data-testid="dashboard-card">
    <gl-card
      class="gl-w-full focus-within:gl-focus hover:!gl-border-strong"
      header-class="!gl-p-0 gl-overflow-hidden"
      body-class="gl-flex gl-grow gl-flex-col"
      footer-class="gl-flex gl-items-center gl-gap-2"
    >
      <template #header>
        <dashboard-card-thumbnail :seed-key="thumbnailSeedKey" :pieces="thumbnailPieces" />
      </template>
      <dashboards-list-name-cell
        :name="dashboard.name"
        :description="dashboard.description"
        :dashboard-url="dashboard.dashboardUrl"
        stretched
      />
      <template #footer>
        <dashboards-list-author :dashboard="dashboard" />
        <template v-if="!dashboard.system">
          <span v-if="dashboard.createdBy" aria-hidden="true" class="gl-text-sm gl-text-subtle"
            >·</span
          >
          <!-- aria-label keeps the focusable time announcing the full sentence;
               it contains the visible text, satisfying label-in-name. -->
          <span
            class="gl-whitespace-nowrap gl-text-sm gl-text-subtle"
            data-testid="dashboard-updated-at"
          >
            <time-ago-tooltip :aria-label="updatedLabel" :time="dashboard.updatedAt" />
          </span>
        </template>
        <!-- gl-z-1 keeps the dropdown clickable above the name cell's stretched link. -->
        <div class="gl-relative gl-z-1 gl-ml-auto" data-testid="dashboard-card-actions">
          <dashboards-list-item-actions
            :id="dashboard.id"
            :name="dashboard.name"
            :action-label="actionsLabel"
            :dashboard-url="dashboard.dashboardUrl"
            :system="dashboard.system"
          />
        </div>
      </template>
    </gl-card>
  </li>
</template>
