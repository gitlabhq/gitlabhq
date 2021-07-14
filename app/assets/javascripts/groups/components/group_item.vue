<script>
import {
  GlAvatar,
  GlLoadingIcon,
  GlBadge,
  GlIcon,
  GlTooltipDirective,
  GlSafeHtmlDirective,
} from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '../constants';
import eventHub from '../event_hub';

import itemActions from './item_actions.vue';
import itemCaret from './item_caret.vue';
import itemStats from './item_stats.vue';
import itemTypeIcon from './item_type_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
  },
  components: {
    GlAvatar,
    GlBadge,
    GlLoadingIcon,
    GlIcon,
    UserAccessRoleBadge,
    itemCaret,
    itemTypeIcon,
    itemStats,
    itemActions,
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
    isGroup() {
      return this.group.type === 'group';
    },
    isGroupPendingRemoval() {
      return this.group.type === 'group' && this.group.pendingRemoval;
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
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>

<template>
  <li
    :id="groupDomId"
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
        <item-type-icon :item-type="group.type" :is-group-open="group.isOpen" />
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
          shape="rect"
          :entity-name="group.name"
          :src="group.avatarUrl"
          :alt="group.name"
          :size="32"
          :itemprop="microdata.imageItemprop"
        />
      </a>
      <div class="group-text-container d-flex flex-fill align-items-center">
        <div class="group-text flex-grow-1 flex-shrink-1">
          <div class="d-flex align-items-center flex-wrap title namespace-title gl-mr-3">
            <a
              v-gl-tooltip.bottom
              data-testid="group-name"
              :href="group.relativePath"
              :title="group.fullName"
              class="no-expand gl-mr-3 gl-mt-3 gl-text-gray-900!"
              :itemprop="microdata.nameItemprop"
            >
              {{
                // ending bracket must be by closing tag to prevent
                // link hover text-decoration from over-extending
                group.name
              }}
            </a>
            <gl-icon
              v-gl-tooltip.hover.bottom
              class="gl-display-inline-flex gl-align-items-center gl-mr-3 gl-mt-3 gl-text-gray-500"
              :name="visibilityIcon"
              :title="visibilityTooltip"
              data-testid="group-visibility-icon"
            />
            <user-access-role-badge v-if="group.permission" class="gl-mt-3">
              {{ group.permission }}
            </user-access-role-badge>
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
        <div class="metadata d-flex flex-grow-1 flex-shrink-0 flex-wrap justify-content-md-between">
          <item-actions
            v-if="isGroup"
            :group="group"
            :parent-group="parentGroup"
            :action="action"
          />
          <item-stats
            :item="group"
            class="group-stats gl-mt-2 d-none d-md-flex gl-align-items-center"
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
