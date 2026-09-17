<script>
import GITLAB_LOGO_SVG_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { GlAvatarLabeled, GlAvatarLink, GlSprintf } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DashboardsListItemActions from 'ee_else_ce/vue_shared/components/dashboards_list/dashboards_list_item_actions.vue';
import DashboardCardThumbnail from './dashboard_card_thumbnail.vue';
import DashboardsListNameCell from './dashboards_list_name_cell.vue';
import { configToPreviewPieces } from './dashboard_preview_layout';

export default {
  name: 'DashboardCard',
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlSprintf,
    DashboardCardThumbnail,
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
      return sprintf(s__('AnalyticsDashboards|More actions for %{name}'), {
        name: this.dashboard.name,
      });
    },
    authorLabel() {
      return sprintf(s__('AnalyticsDashboards|By %{name}'), {
        name: this.dashboard.system
          ? this.$options.createdByGitLab.label
          : this.dashboard.createdBy?.name,
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
  avatarSize: 24,
  createdByGitLab: {
    avatarUrl: GITLAB_LOGO_SVG_URL,
    label: __('GitLab'),
  },
};
</script>
<template>
  <li
    class="gl-border gl-relative gl-flex gl-flex-col gl-rounded-lg gl-border-default gl-bg-default gl-transition-all focus-within:-gl-translate-y-1 focus-within:gl-shadow-md hover:-gl-translate-y-1 hover:gl-shadow-md"
    data-testid="dashboard-card"
  >
    <dashboard-card-thumbnail :seed-key="thumbnailSeedKey" :pieces="thumbnailPieces" />
    <div class="gl-flex gl-grow gl-flex-col gl-gap-2 gl-p-5">
      <dashboards-list-name-cell
        :name="dashboard.name"
        :description="dashboard.description"
        :dashboard-url="dashboard.dashboardUrl"
        stretched
      />
      <div class="gl-mt-auto gl-flex gl-flex-wrap gl-items-center gl-gap-2 gl-pt-4">
        <gl-avatar-labeled
          v-if="dashboard.system"
          :src="$options.createdByGitLab.avatarUrl"
          :size="$options.avatarSize"
          :label="authorLabel"
          shape="circle"
          fallback-on-error
        />
        <gl-avatar-link
          v-else-if="dashboard.createdBy"
          class="gl-relative gl-z-1"
          :href="dashboard.createdBy.webPath"
        >
          <gl-avatar-labeled
            :src="dashboard.createdBy.avatarUrl"
            :size="$options.avatarSize"
            :label="authorLabel"
            shape="circle"
            fallback-on-error
          />
        </gl-avatar-link>
        <template v-if="!dashboard.system">
          <span v-if="dashboard.createdBy" aria-hidden="true" class="gl-text-sm gl-text-subtle"
            >·</span
          >
          <span class="gl-text-sm gl-text-subtle" data-testid="dashboard-updated-at">
            <gl-sprintf :message="__('Updated %{timeAgo}')">
              <template #timeAgo>
                <time-ago-tooltip :time="dashboard.updatedAt" />
              </template>
            </gl-sprintf>
          </span>
        </template>
      </div>
    </div>
    <!-- After the name cell so tab order reads name-then-actions; gl-absolute escapes
         the thumbnail's overflow clipping and gl-z-1 sits above the stretched link. -->
    <div class="gl-absolute gl-right-3 gl-top-3 gl-z-1" data-testid="dashboard-card-actions">
      <dashboards-list-item-actions
        :id="dashboard.id"
        :action-label="actionsLabel"
        :dashboard-url="dashboard.dashboardUrl"
        :system="dashboard.system"
      />
    </div>
  </li>
</template>
