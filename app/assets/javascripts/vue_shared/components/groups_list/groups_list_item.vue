<script>
import { GlAvatarLabeled, GlIcon, GlTooltipDirective, GlTruncateText, GlBadge } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';

import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { __ } from '~/locale';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import DangerConfirmModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';

export default {
  i18n: {
    subgroups: __('Subgroups'),
    projects: __('Projects'),
    directMembers: __('Direct members'),
    showMore: __('Show more'),
    showLess: __('Show less'),
  },
  truncateTextToggleButtonProps: { class: 'gl-font-sm!' },
  components: {
    GlAvatarLabeled,
    GlIcon,
    GlTruncateText,
    GlBadge,
    ListActions,
    DangerConfirmModal,
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
  },
  methods: {
    onActionDelete() {
      this.isDeleteModalVisible = true;
    },
  },
};
</script>

<template>
  <li class="groups-list-item gl-py-5 gl-border-b gl-display-flex">
    <div class="gl-md-display-flex gl-flex-grow-1">
      <div class="gl-display-flex gl-flex-grow-1">
        <div
          v-if="showGroupIcon"
          class="gl-display-flex gl-align-items-center gl-flex-shrink-0 gl-h-9 gl-mr-3"
        >
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
                  <gl-badge
                    v-if="shouldShowAccessLevel"
                    size="sm"
                    class="gl-display-block"
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
              class="gl-font-sm gl-text-secondary md"
              data-testid="group-description"
            ></div>
          </gl-truncate-text>
        </gl-avatar-labeled>
      </div>
      <div
        class="gl-display-flex gl-align-items-center gl-gap-x-3 gl-flex-shrink-0 gl-mt-3 gl-md-pl-0 gl-md-mt-0 gl-md-ml-3 gl-md-h-9"
        :class="statsPadding"
      >
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
    </div>
    <div class="gl-display-flex gl-align-items-center gl-h-9 gl-ml-3">
      <list-actions
        v-if="hasActions"
        :actions="actions"
        :available-actions="group.availableActions"
      />
    </div>

    <danger-confirm-modal
      v-if="hasActionDelete"
      v-model="isDeleteModalVisible"
      :modal-id="modalId"
      :phrase="group.fullName"
      :confirm-loading="isActionDeleteLoading"
      @confirm.prevent="$emit('delete', group)"
    />
  </li>
</template>
