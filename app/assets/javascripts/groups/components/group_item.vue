<script>
import {
  GlLoadingIcon,
  GlBadge,
  GlButton,
  GlTooltipDirective,
  GlAnimatedChevronRightDownIcon,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { visitUrl } from '~/lib/utils/url_utility';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import VisibilityIconButton from '~/vue_shared/components/visibility_icon_button.vue';
import { __ } from '~/locale';
import { ITEM_TYPE } from '../constants';

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
    GlAnimatedChevronRightDownIcon,
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
      return `groups-list-item-${this.group.id}`;
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
    isGroup() {
      return this.group.type === ITEM_TYPE.GROUP;
    },
    microdata() {
      return this.group.microdata || {};
    },
    showActionsMenu() {
      return this.isGroup && (this.group.canEdit || this.group.canRemove || this.group.canLeave);
    },
    toggleAriaLabel() {
      return this.group.isOpen ? this.$options.i18n.collapse : this.$options.i18n.expand;
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
  },
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
          data-testid="nested-groups-project-list-item-toggle-button"
          class="btn-icon"
          @click.stop="onClickRowGroup"
        >
          <gl-animated-chevron-right-down-icon :is-on="group.isOpen" />
        </gl-button>
        <div v-else class="gl-h-7 gl-w-7"></div>
        <item-type-icon :item-type="group.type" />
      </div>
      <gl-loading-icon
        v-if="group.isChildrenLoading"
        size="lg"
        class="gl-mr-3 gl-hidden gl-shrink-0 @sm/panel:gl-inline-flex"
      />
      <a
        :class="{ '@sm/panel:gl-flex': !group.isChildrenLoading }"
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
        <div v-if="group.isSelfDeletionInProgress">
          <gl-badge variant="warning">{{ __('Deletion in progress') }}</gl-badge>
        </div>
        <div v-else-if="group.markedForDeletion">
          <gl-badge variant="warning">{{ __('Pending deletion') }}</gl-badge>
        </div>
        <div v-else-if="group.archived">
          <gl-badge variant="info">{{ __('Archived') }}</gl-badge>
        </div>
        <div class="metadata gl-flex gl-shrink-0 gl-grow gl-flex-wrap @md/panel:gl-justify-between">
          <item-stats
            :item="group"
            class="group-stats gl-hidden gl-items-center @md/panel:gl-flex"
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
    <!-- eslint-disable-next-line vue/no-undef-components -->
    <group-folder
      v-if="group.isOpen && hasChildren"
      :parent-group="group"
      :groups="group.children"
      :action="action"
    />
  </li>
</template>
