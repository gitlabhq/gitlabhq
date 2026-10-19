<script>
import GITLAB_LOGO_SVG_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  name: 'DashboardsListAuthor',
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
  },
  props: {
    dashboard: {
      type: Object,
      required: true,
    },
  },
  computed: {
    authorName() {
      return this.dashboard.system
        ? this.$options.createdByGitLab.label
        : this.dashboard.createdBy?.name;
    },
    // Full sentence so translations keep their own word order; the visible
    // label shows only the name.
    authorSrLabel() {
      return sprintf(s__('AnalyticsDashboards|Created by %{name}'), { name: this.authorName });
    },
    // Numeric id seeding the identicon's background when the avatar image fails.
    creatorEntityId() {
      return getIdFromGraphQLId(this.dashboard.createdBy?.id) || 0;
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
  <!-- The sr-only sentence announces authorship, so the decorative avatar block is
       hidden from assistive technology. -->
  <span v-if="dashboard.system">
    <span class="gl-sr-only" data-testid="dashboard-card-authorship">{{ authorSrLabel }}</span>
    <span aria-hidden="true">
      <gl-avatar-labeled
        :src="$options.createdByGitLab.avatarUrl"
        :size="$options.avatarSize"
        :label="authorName"
        :entity-name="$options.createdByGitLab.label"
        shape="circle"
        fallback-on-error
      />
    </span>
  </span>
  <!-- aria-label keeps the link's accessible name a full sentence; it contains the
       visible name, satisfying label-in-name. -->
  <gl-avatar-link
    v-else-if="dashboard.createdBy"
    class="gl-relative gl-z-1 gl-min-w-0 gl-break-anywhere"
    :href="dashboard.createdBy.webPath"
    :aria-label="authorSrLabel"
  >
    <!-- entity-name/entity-id seed the identicon fallback so a broken avatar image
         degrades to a lettered circle rather than a blank one. -->
    <gl-avatar-labeled
      :src="dashboard.createdBy.avatarUrl"
      :size="$options.avatarSize"
      :label="authorName"
      :entity-name="dashboard.createdBy.name"
      :entity-id="creatorEntityId"
      shape="circle"
      fallback-on-error
    />
  </gl-avatar-link>
</template>
