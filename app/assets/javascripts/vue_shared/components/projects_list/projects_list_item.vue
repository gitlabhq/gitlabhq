<script>
import { GlAvatarLabeled, GlIcon, GlLink, GlBadge, GlTooltipDirective } from '@gitlab/ui';

import { VISIBILITY_TYPE_ICON, PROJECT_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import { FEATURABLE_ENABLED } from '~/featurable/constants';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { __ } from '~/locale';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';

export default {
  i18n: {
    stars: __('Stars'),
    forks: __('Forks'),
    issues: __('Issues'),
    archived: __('Archived'),
  },
  components: {
    GlAvatarLabeled,
    GlIcon,
    UserAccessRoleBadge,
    GlLink,
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    /**
     * Expected format:
     *
     * {
     *   id: number | string;
     *   name: string;
     *   webUrl: string;
     *   forksCount?: number;
     *   avatarUrl: string | null;
     *   starCount: number;
     *   visibility: string;
     *   issuesAccessLevel: string;
     *   forkingAccessLevel: string;
     *   openIssuesCount: number;
     *   permissions: {
     *     projectAccess: { accessLevel: 50 };
     *   };
     */
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.project.visibility];
    },
    visibilityTooltip() {
      return PROJECT_VISIBILITY_TYPE[this.project.visibility];
    },
    accessLevel() {
      return this.project.permissions?.projectAccess?.accessLevel;
    },
    accessLevelLabel() {
      return ACCESS_LEVEL_LABELS[this.accessLevel];
    },
    shouldShowAccessLevel() {
      return this.accessLevel !== undefined;
    },
    starsHref() {
      return `${this.project.webUrl}/-/starrers`;
    },
    forksHref() {
      return `${this.project.webUrl}/-/forks`;
    },
    issuesHref() {
      return `${this.project.webUrl}/-/issues`;
    },
    isForkingEnabled() {
      return (
        this.project.forkingAccessLevel === FEATURABLE_ENABLED &&
        this.project.forksCount !== undefined
      );
    },
    isIssuesEnabled() {
      return this.project.issuesAccessLevel === FEATURABLE_ENABLED;
    },
  },
  methods: {
    numberToMetricPrefix,
  },
};
</script>

<template>
  <li class="gl-py-5 gl-md-display-flex gl-align-items-center gl-border-b">
    <gl-avatar-labeled
      class="gl-flex-grow-1"
      :entity-id="project.id"
      :entity-name="project.name"
      :label="project.name"
      :label-link="project.webUrl"
      shape="rect"
      :size="48"
    >
      <template #meta>
        <gl-icon
          v-gl-tooltip="visibilityTooltip"
          :name="visibilityIcon"
          class="gl-text-secondary gl-ml-3"
        />
        <user-access-role-badge v-if="shouldShowAccessLevel" class="gl-ml-3">{{
          accessLevelLabel
        }}</user-access-role-badge>
      </template>
    </gl-avatar-labeled>
    <div
      class="gl-md-display-flex gl-flex-direction-column gl-align-items-flex-end gl-flex-shrink-0 gl-mt-3 gl-md-mt-0"
    >
      <div class="gl-display-flex gl-align-items-center gl-gap-x-3">
        <gl-badge v-if="project.archived" variant="warning">{{ $options.i18n.archived }}</gl-badge>
        <gl-link
          v-gl-tooltip="$options.i18n.stars"
          :href="starsHref"
          :aria-label="$options.i18n.stars"
          class="gl-text-secondary"
        >
          <gl-icon name="star-o" />
          <span>{{ numberToMetricPrefix(project.starCount) }}</span>
        </gl-link>
        <gl-link
          v-if="isForkingEnabled"
          v-gl-tooltip="$options.i18n.forks"
          :href="forksHref"
          :aria-label="$options.i18n.forks"
          class="gl-text-secondary"
        >
          <gl-icon name="fork" />
          <span>{{ numberToMetricPrefix(project.forksCount) }}</span>
        </gl-link>
        <gl-link
          v-if="isIssuesEnabled"
          v-gl-tooltip="$options.i18n.issues"
          :href="issuesHref"
          :aria-label="$options.i18n.issues"
          class="gl-text-secondary"
        >
          <gl-icon name="issues" />
          <span>{{ numberToMetricPrefix(project.openIssuesCount) }}</span>
        </gl-link>
      </div>
    </div>
  </li>
</template>
