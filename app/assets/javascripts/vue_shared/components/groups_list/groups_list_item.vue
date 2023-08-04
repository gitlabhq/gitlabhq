<script>
import { GlAvatarLabeled, GlIcon, GlTooltipDirective, GlTruncateText } from '@gitlab/ui';

import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { __ } from '~/locale';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  i18n: {
    subgroups: __('Subgroups'),
    projects: __('Projects'),
    directMembers: __('Direct members'),
    showMore: __('Show more'),
    showLess: __('Show less'),
  },
  avatarSize: { default: 32, md: 48 },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
  components: {
    GlAvatarLabeled,
    GlIcon,
    UserAccessRoleBadge,
    GlTruncateText,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    showGroupIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    visibility() {
      return this.group.visibility;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.visibility];
    },
    visibilityTooltip() {
      return GROUP_VISIBILITY_TYPE[this.visibility];
    },
    accessLevel() {
      return this.group.accessLevel?.integerValue;
    },
    accessLevelLabel() {
      return ACCESS_LEVEL_LABELS[this.accessLevel];
    },
    shouldShowAccessLevel() {
      return this.accessLevel !== undefined;
    },
    groupIconName() {
      return this.group.parent ? 'subgroup' : 'group';
    },
    statsPadding() {
      return this.showGroupIcon ? 'gl-pl-11' : 'gl-pl-8';
    },
    descendantGroupsCount() {
      return numberToMetricPrefix(this.group.descendantGroupsCount);
    },
    projectsCount() {
      return numberToMetricPrefix(this.group.projectsCount);
    },
    groupMembersCount() {
      return numberToMetricPrefix(this.group.groupMembersCount);
    },
  },
};
</script>

<template>
  <li class="groups-list-item gl-py-5 gl-md-display-flex gl-align-items-center gl-border-b">
    <div class="gl-display-flex gl-flex-grow-1">
      <gl-icon
        v-if="showGroupIcon"
        class="gl-mr-3 gl-mt-3 gl-md-mt-5 gl-flex-shrink-0 gl-text-secondary"
        :name="groupIconName"
      />
      <gl-avatar-labeled
        :entity-id="group.id"
        :entity-name="group.fullName"
        :label="group.fullName"
        :label-link="group.webUrl"
        shape="rect"
        :size="$options.avatarSize"
      >
        <template #meta>
          <div class="gl-px-2">
            <div class="gl-mx-n2 gl-display-flex gl-align-items-center gl-flex-wrap">
              <div class="gl-px-2">
                <gl-icon
                  v-if="visibility"
                  v-gl-tooltip="visibilityTooltip"
                  :name="visibilityIcon"
                  class="gl-text-secondary"
                />
              </div>
              <div class="gl-px-2">
                <user-access-role-badge v-if="shouldShowAccessLevel">{{
                  accessLevelLabel
                }}</user-access-role-badge>
              </div>
            </div>
          </div>
        </template>
        <gl-truncate-text
          v-if="group.descriptionHtml"
          :lines="2"
          :mobile-lines="2"
          :show-more-text="$options.i18n.showMore"
          :show-less-text="$options.i18n.showLess"
          class="gl-mt-2"
        >
          <div
            v-safe-html:[$options.safeHtmlConfig]="group.descriptionHtml"
            class="gl-font-sm md"
            data-testid="group-description"
          ></div>
        </gl-truncate-text>
      </gl-avatar-labeled>
    </div>
    <div
      class="gl-md-display-flex gl-flex-direction-column gl-align-items-flex-end gl-flex-shrink-0 gl-mt-3 gl-md-pl-0 gl-md-mt-0 gl-md-ml-3"
      :class="statsPadding"
    >
      <div class="gl-display-flex gl-align-items-center gl-gap-x-3">
        <div
          v-gl-tooltip="$options.i18n.subgroups"
          :aria-label="$options.i18n.subgroups"
          class="gl-text-secondary"
          data-testid="subgroups-count"
        >
          <gl-icon name="subgroup" />
          <span>{{ descendantGroupsCount }}</span>
        </div>
        <div
          v-gl-tooltip="$options.i18n.projects"
          :aria-label="$options.i18n.projects"
          class="gl-text-secondary"
          data-testid="projects-count"
        >
          <gl-icon name="project" />
          <span>{{ projectsCount }}</span>
        </div>
        <div
          v-gl-tooltip="$options.i18n.directMembers"
          :aria-label="$options.i18n.directMembers"
          class="gl-text-secondary"
          data-testid="members-count"
        >
          <gl-icon name="users" />
          <span>{{ groupMembersCount }}</span>
        </div>
      </div>
    </div>
  </li>
</template>
