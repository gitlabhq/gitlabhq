<script>
import { GlAvatarLabeled, GlIcon, GlTooltipDirective, GlTruncateText, GlBadge } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';

import GroupListItemDeleteModal from 'ee_else_ce/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { __ } from '~/locale';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

export default {
  i18n: {
    subgroups: __('Subgroups'),
    projects: __('Projects'),
    directMembers: __('Direct members'),
    showMore: __('Show more'),
    showLess: __('Show less'),
    [TIMESTAMP_TYPE_CREATED_AT]: __('Created'),
    [TIMESTAMP_TYPE_UPDATED_AT]: __('Updated'),
  },
  truncateTextToggleButtonProps: { class: '!gl-text-sm' },
  components: {
    GlAvatarLabeled,
    GlIcon,
    GlTruncateText,
    GlBadge,
    ListActions,
    GroupListItemDeleteModal,
    TimeAgoTooltip,
    GroupListItemInactiveBadge: () =>
      import('ee_component/vue_shared/components/groups_list/group_list_item_inactive_badge.vue'),
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
    timestampType: {
      type: String,
      required: false,
      default: TIMESTAMP_TYPE_CREATED_AT,
      validator(value) {
        return [TIMESTAMP_TYPE_CREATED_AT, TIMESTAMP_TYPE_UPDATED_AT].includes(value);
      },
    },
  },
  data() {
    return {
      isDeleteModalVisible: false,
      modalId: uniqueId('groups-list-item-modal-id-'),
    };
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
      return this.accessLevel !== undefined && this.accessLevel !== ACCESS_LEVEL_NO_ACCESS_INTEGER;
    },
    groupIconName() {
      return this.group.parent ? 'subgroup' : 'group';
    },
    statsPadding() {
      return this.showGroupIcon ? 'gl-pl-12' : 'gl-pl-10';
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
    actions() {
      return {
        [ACTION_EDIT]: {
          href: this.group.editPath,
        },
        [ACTION_DELETE]: {
          action: this.onActionDelete,
        },
      };
    },
    hasActions() {
      return this.group.availableActions?.length;
    },
    hasActionDelete() {
      return this.group.availableActions?.includes(ACTION_DELETE);
    },
    isActionDeleteLoading() {
      return this.group.actionLoadingStates?.[ACTION_DELETE];
    },
    timestampText() {
      return this.$options.i18n[this.timestampType];
    },
    timestamp() {
      return this.group[this.timestampType];
    },
  },
  methods: {
    onActionDelete() {
      this.isDeleteModalVisible = true;
    },
  },
};
</script>

<template>
  <li class="groups-list-item gl-border-b gl-flex gl-py-5">
    <div class="gl-grow md:gl-flex">
      <div class="gl-flex gl-grow gl-items-start">
        <div v-if="showGroupIcon" class="gl-mr-3 gl-flex gl-h-9 gl-flex-shrink-0 gl-items-center">
          <gl-icon class="gl-text-secondary" :name="groupIconName" />
        </div>
        <gl-avatar-labeled
          :entity-id="group.id"
          :entity-name="group.fullName"
          :label="group.fullName"
          :label-link="group.webUrl"
          shape="rect"
          :size="48"
        >
          <template #meta>
            <div class="gl-px-2">
              <div class="-gl-mx-2 gl-flex gl-flex-wrap gl-items-center">
                <div class="gl-px-2">
                  <gl-icon
                    v-if="visibility"
                    v-gl-tooltip="visibilityTooltip"
                    :name="visibilityIcon"
                    class="gl-text-secondary"
                  />
                </div>
                <div class="gl-px-2">
                  <gl-badge
                    v-if="shouldShowAccessLevel"
                    class="gl-block"
                    data-testid="access-level-badge"
                    >{{ accessLevelLabel }}</gl-badge
                  >
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
            :toggle-button-props="$options.truncateTextToggleButtonProps"
            class="gl-mt-2 gl-max-w-88"
          >
            <div
              v-safe-html="group.descriptionHtml"
              class="md gl-text-sm gl-text-secondary"
              data-testid="group-description"
            ></div>
          </gl-truncate-text>
        </gl-avatar-labeled>
      </div>
      <div
        class="gl-mt-3 gl-shrink-0 gl-flex-col gl-items-end md:gl-mt-0 md:gl-flex md:gl-pl-0"
        :class="statsPadding"
      >
        <div class="gl-flex gl-items-center gl-gap-x-3 md:gl-h-9">
          <group-list-item-inactive-badge :group="group" />
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
        <div
          v-if="timestamp"
          class="gl-mt-3 gl-whitespace-nowrap gl-text-sm gl-text-secondary md:-gl-mt-2"
        >
          <span>{{ timestampText }}</span>
          <time-ago-tooltip :time="timestamp" />
        </div>
      </div>
    </div>
    <div class="gl-ml-3 gl-flex gl-h-9 gl-items-center">
      <list-actions
        v-if="hasActions"
        :actions="actions"
        :available-actions="group.availableActions"
      />
    </div>

    <group-list-item-delete-modal
      v-if="hasActionDelete"
      :visible="isDeleteModalVisible"
      :modal-id="modalId"
      :phrase="group.fullName"
      :confirm-loading="isActionDeleteLoading"
      :group="group"
      @confirm.prevent="$emit('delete', group)"
      @change="isDeleteModalVisible = arguments[0]"
    />
  </li>
</template>
