<script>
import {
  GlAvatar,
  GlLoadingIcon,
  GlBadge,
  GlIcon,
  GlLabel,
  GlButton,
  GlPopover,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { visitUrl } from '~/lib/utils/url_utility';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import {
  VISIBILITY_LEVELS_STRING_TO_INTEGER,
  VISIBILITY_TYPE_ICON,
  GROUP_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { ITEM_TYPE } from '../constants';

import eventHub from '../event_hub';

import ItemActions from './item_actions.vue';
import ItemCaret from './item_caret.vue';
import ItemStats from './item_stats.vue';
import ItemTypeIcon from './item_type_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  components: {
    GlAvatar,
    GlBadge,
    GlLoadingIcon,
    GlIcon,
    GlLabel,
    GlButton,
    GlPopover,
    GlLink,
    UserAccessRoleBadge,
    ItemCaret,
    ItemTypeIcon,
    ItemActions,
    ItemStats,
  },
  inject: ['currentGroupVisibility'],
  props: {
    parentGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    group: {
      type: Object,
      required: true,
    },
    action: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    groupDomId() {
      return `group-${this.group.id}`;
    },
    itemTestId() {
      return `group-overview-item-${this.group.id}`;
    },
    rowClass() {
      return {
        'is-open': this.group.isOpen,
        'has-children': this.hasChildren,
        'has-description': this.group.description,
        'being-removed': this.group.isBeingRemoved,
      };
    },
    hasChildren() {
      return this.group.childrenCount > 0;
    },
    hasAvatar() {
      return this.group.avatarUrl !== null;
    },
    hasComplianceFramework() {
      return Boolean(this.group.complianceFramework?.name);
    },
    isGroup() {
      return this.group.type === ITEM_TYPE.GROUP;
    },
    isGroupPendingRemoval() {
      return this.group.type === ITEM_TYPE.GROUP && this.group.pendingRemoval;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.group.visibility];
    },
    visibilityTooltip() {
      return GROUP_VISIBILITY_TYPE[this.group.visibility];
    },
    microdata() {
      return this.group.microdata || {};
    },
    complianceFramework() {
      return this.group.complianceFramework;
    },
    showActionsMenu() {
      return this.isGroup && (this.group.canEdit || this.group.canRemove || this.group.canLeave);
    },
    shouldShowVisibilityWarning() {
      return (
        this.action === 'shared' &&
        VISIBILITY_LEVELS_STRING_TO_INTEGER[this.group.visibility] >
          VISIBILITY_LEVELS_STRING_TO_INTEGER[this.currentGroupVisibility]
      );
    },
  },
  methods: {
    onClickRowGroup(e) {
      const NO_EXPAND_CLS = 'no-expand';
      const targetClasses = e.target.classList;
      const parentElClasses = e.target.parentElement.classList;

      if (!(targetClasses.contains(NO_EXPAND_CLS) || parentElClasses.contains(NO_EXPAND_CLS))) {
        if (this.hasChildren) {
          eventHub.$emit(`${this.action}toggleChildren`, this.group);
        } else {
          visitUrl(this.group.relativePath);
        }
      }
    },
  },
  i18n: {
    popoverTitle: __('Less restrictive visibility'),
    popoverBody: __('Project visibility level is less restrictive than the group settings.'),
    learnMore: __('Learn more'),
  },
  shareProjectsWithGroupsHelpPagePath: helpPagePath(
    'user/project/members/share_project_with_groups',
    {
      anchor: 'sharing-projects-with-groups-of-a-higher-restrictive-visibility-level',
    },
  ),
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <li
    :id="groupDomId"
    :data-testid="itemTestId"
    :class="rowClass"
    class="group-row"
    :itemprop="microdata.itemprop"
    :itemtype="microdata.itemtype"
    :itemscope="microdata.itemscope"
    @click.stop="onClickRowGroup"
  >
    <div
      :class="{ 'project-row-contents': !isGroup }"
      class="group-row-contents d-flex align-items-center py-2 pr-3"
    >
      <div class="folder-toggle-wrap gl-mr-2 d-flex align-items-center">
        <item-caret :is-group-open="group.isOpen" />
        <item-type-icon :item-type="group.type" />
      </div>
      <gl-loading-icon
        v-if="group.isChildrenLoading"
        size="lg"
        class="d-none d-sm-inline-flex flex-shrink-0 gl-mr-3"
      />
      <a
        :class="{ 'gl-sm-display-flex': !group.isChildrenLoading }"
        class="gl-display-none gl-text-decoration-none! gl-mr-3"
        :href="group.relativePath"
        :aria-label="group.name"
      >
        <gl-avatar
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :entity-id="group.id"
          :entity-name="group.name"
          :src="group.avatarUrl"
          :alt="group.name"
          :size="32"
          :itemprop="microdata.imageItemprop"
        />
      </a>
      <div class="group-text-container d-flex flex-fill align-items-center">
        <div class="group-text flex-grow-1 flex-shrink-1">
          <div
            class="gl-display-flex gl-align-items-center gl-flex-wrap title namespace-title gl-font-weight-bold gl-mr-3"
          >
            <a
              v-gl-tooltip.bottom
              data-testid="group-name"
              :href="group.relativePath"
              :title="group.fullName"
              class="no-expand gl-mr-3 gl-text-gray-900!"
              :itemprop="microdata.nameItemprop"
            >
              <!-- ending bracket must be by closing tag to prevent -->
              <!-- link hover text-decoration from over-extending -->
              {{ group.name }}
            </a>
            <gl-icon
              v-gl-tooltip.hover.bottom
              class="gl-display-inline-flex gl-align-items-center gl-mr-3 gl-text-gray-500"
              :name="visibilityIcon"
              :title="visibilityTooltip"
              data-testid="group-visibility-icon"
            />
            <template v-if="shouldShowVisibilityWarning">
              <gl-button
                ref="visibilityWarningButton"
                class="gl-p-1! gl-bg-transparent! gl-mr-3"
                category="tertiary"
                icon="warning"
                :aria-label="$options.i18n.popoverTitle"
                @click.stop
              />
              <gl-popover
                :target="() => $refs.visibilityWarningButton.$el"
                :title="$options.i18n.popoverTitle"
                triggers="hover focus"
              >
                {{ $options.i18n.popoverBody }}
                <div class="gl-mt-3">
                  <gl-link
                    class="gl-font-sm"
                    :href="$options.shareProjectsWithGroupsHelpPagePath"
                    >{{ $options.i18n.learnMore }}</gl-link
                  >
                </div>
              </gl-popover>
            </template>
            <user-access-role-badge v-if="group.permission" class="gl-mr-3">
              {{ group.permission }}
            </user-access-role-badge>
            <gl-label
              v-if="hasComplianceFramework"
              :title="complianceFramework.name"
              :background-color="complianceFramework.color"
              :description="complianceFramework.description"
              size="sm"
            />
          </div>
          <div v-if="group.description" class="description">
            <span
              v-safe-html:[$options.safeHtmlConfig]="group.description"
              :itemprop="microdata.descriptionItemprop"
              data-testid="group-description"
            >
            </span>
          </div>
        </div>
        <div v-if="isGroupPendingRemoval">
          <gl-badge variant="warning">{{ __('pending deletion') }}</gl-badge>
        </div>
        <div
          class="metadata gl-display-flex gl-flex-grow-1 gl-flex-shrink-0 gl-flex-wrap justify-content-md-between"
        >
          <item-stats
            :item="group"
            class="group-stats gl-mt-2 gl-display-none gl-md-display-flex gl-align-items-center"
          />
          <item-actions
            v-if="showActionsMenu"
            :group="group"
            :parent-group="parentGroup"
            :action="action"
          />
        </div>
      </div>
    </div>
    <group-folder
      v-if="group.isOpen && hasChildren"
      :parent-group="group"
      :groups="group.children"
      :action="action"
    />
  </li>
</template>
