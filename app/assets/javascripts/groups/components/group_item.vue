<script>
import {
  GlLoadingIcon,
  GlBadge,
  GlButton,
  GlPopover,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { visitUrl } from '~/lib/utils/url_utility';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import VisibilityIconButton from '~/vue_shared/components/visibility_icon_button.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import { VISIBILITY_LEVELS_STRING_TO_INTEGER } from '~/visibility_level/constants';
import { ITEM_TYPE, ACTIVE_TAB_SHARED } from '../constants';

import eventHub from '../event_hub';

import ItemActions from './item_actions.vue';
import ItemStats from './item_stats.vue';
import ItemTypeIcon from './item_type_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  components: {
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlPopover,
    GlLink,
    UserAccessRoleBadge,
    ItemTypeIcon,
    ItemActions,
    ItemStats,
    ProjectAvatar,
    VisibilityIconButton,
  },
  inject: {
    currentGroupVisibility: {
      default: '',
    },
  },
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
      return this.group.hasChildren;
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
        this.action === ACTIVE_TAB_SHARED &&
        VISIBILITY_LEVELS_STRING_TO_INTEGER[this.group.visibility] >
          VISIBILITY_LEVELS_STRING_TO_INTEGER[this.currentGroupVisibility]
      );
    },
    toggleAriaLabel() {
      return this.group.isOpen ? this.$options.i18n.collapse : this.$options.i18n.expand;
    },
    toggleIconName() {
      return this.group.isOpen ? 'chevron-down' : 'chevron-right';
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
    expand: __('Expand'),
    collapse: __('Collapse'),
    popoverTitle: __('Less restrictive visibility'),
    popoverBody: __('Project visibility level is less restrictive than the group settings.'),
    learnMore: __('Learn more'),
  },
  shareProjectsWithGroupsHelpPagePath: helpPagePath('user/project/members/sharing_projects_groups'),
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
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
      class="group-row-contents gl-flex gl-items-center gl-py-3 gl-pr-5"
    >
      <div class="folder-toggle-wrap gl-mr-2 gl-flex gl-items-center">
        <gl-button
          v-if="hasChildren"
          :aria-label="toggleAriaLabel"
          :aria-expanded="String(group.isOpen)"
          category="tertiary"
          data-testid="group-item-toggle-button"
          :icon="toggleIconName"
          @click.stop="onClickRowGroup"
        />
        <div v-else class="gl-h-7 gl-w-7"></div>
        <item-type-icon :item-type="group.type" />
      </div>
      <gl-loading-icon
        v-if="group.isChildrenLoading"
        size="lg"
        class="gl-mr-3 gl-hidden gl-shrink-0 sm:gl-inline-flex"
      />
      <a
        :class="{ 'sm:gl-flex': !group.isChildrenLoading }"
        class="gl-mr-3 gl-hidden !gl-no-underline"
        :href="group.relativePath"
        :aria-label="group.name"
      >
        <project-avatar
          :alt="group.name"
          :itemprop="microdata.imageItemprop"
          :project-avatar-url="group.avatarUrl"
          :project-id="group.id"
          :project-name="group.name"
        />
      </a>
      <div class="group-text-container gl-flex gl-flex-auto gl-items-center">
        <div class="group-text gl-shrink gl-grow">
          <div
            class="title namespace-title gl-mr-3 gl-flex gl-flex-wrap gl-items-center gl-gap-3 gl-font-bold"
          >
            <a
              v-gl-tooltip.bottom
              data-testid="group-name"
              :href="group.relativePath"
              :title="group.fullName"
              class="no-expand !gl-text-default gl-break-anywhere"
              :itemprop="microdata.nameItemprop"
            >
              <!-- ending bracket must be by closing tag to prevent -->
              <!-- link hover text-decoration from over-extending -->
              {{ group.name }}
            </a>
            <visibility-icon-button
              :is-group="isGroup"
              :visibility-level="group.visibility"
              data-testid="group-visibility-icon"
              tooltip-placement="bottom"
            />
            <template v-if="shouldShowVisibilityWarning">
              <gl-button
                ref="visibilityWarningButton"
                class="!gl-bg-transparent !gl-p-1"
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
                    class="gl-text-sm"
                    :href="$options.shareProjectsWithGroupsHelpPagePath"
                    >{{ $options.i18n.learnMore }}</gl-link
                  >
                </div>
              </gl-popover>
            </template>
            <user-access-role-badge v-if="group.permission" class="gl-mr-2">
              {{ group.permission }}
            </user-access-role-badge>
          </div>
          <div v-if="group.description" class="description gl-mt-1 gl-text-sm">
            <span
              v-safe-html:[$options.safeHtmlConfig]="group.description"
              :itemprop="microdata.descriptionItemprop"
              data-testid="group-description"
            >
            </span>
          </div>
        </div>
        <div v-if="group.pendingRemoval">
          <gl-badge variant="warning">{{ __('Pending deletion') }}</gl-badge>
        </div>
        <div v-else-if="group.archived">
          <gl-badge variant="info">{{ __('Archived') }}</gl-badge>
        </div>
        <div class="metadata gl-flex gl-shrink-0 gl-grow gl-flex-wrap md:gl-justify-between">
          <item-stats :item="group" class="group-stats gl-hidden gl-items-center md:gl-flex" />
          <item-actions
            v-if="showActionsMenu"
            :group="group"
            :parent-group="parentGroup"
            :action="action"
          />
        </div>
      </div>
    </div>
    <!-- eslint-disable-next-line vue/no-undef-components -->
    <group-folder
      v-if="group.isOpen && hasChildren"
      :parent-group="group"
      :groups="group.children"
      :action="action"
    />
  </li>
</template>
