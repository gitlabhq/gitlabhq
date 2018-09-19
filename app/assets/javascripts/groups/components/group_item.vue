<script>
import { visitUrl } from '../../lib/utils/url_utility';
import tooltip from '../../vue_shared/directives/tooltip';
import identicon from '../../vue_shared/components/identicon.vue';
import eventHub from '../event_hub';

import itemCaret from './item_caret.vue';
import itemTypeIcon from './item_type_icon.vue';
import itemStats from './item_stats.vue';
import itemActions from './item_actions.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    identicon,
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
};
</script>

<template>
  <li
    :id="groupDomId"
    :class="rowClass"
    class="group-row"
    @click.stop="onClickRowGroup"
  >
    <div
      :class="{ 'project-row-contents': !isGroup }"
      class="group-row-contents d-flex justify-content-end align-items-center"
    >
      <div
        class="folder-toggle-wrap append-right-4 d-flex align-items-center"
      >
        <item-caret
          :is-group-open="group.isOpen"
        />
        <item-type-icon
          :item-type="group.type"
          :is-group-open="group.isOpen"
        />
      </div>
      <div
        :class="{ 'content-loading': group.isChildrenLoading }"
        class="avatar-container s24 d-none d-sm-flex"
      >
        <a
          :href="group.relativePath"
          class="no-expand"
        >
          <img
            v-if="hasAvatar"
            :src="group.avatarUrl"
            class="avatar s24"
          />
          <identicon
            v-else
            :entity-id="group.id"
            :entity-name="group.name"
            size-class="s24"
          />
        </a>
      </div>
      <div
        class="group-text flex-grow"
      >
        <div
          class="title namespace-title append-right-8"
        >
          <a
            v-tooltip
            :href="group.relativePath"
            :title="group.fullName"
            class="no-expand"
            data-placement="bottom"
          >{{
            // ending bracket must be by closing tag to prevent
            // link hover text-decoration from over-extending
            group.name
          }}</a>
          <span
            v-if="group.permission"
            class="user-access-role"
          >
            {{ group.permission }}
          </span>
        </div>
        <div
          v-if="group.description"
          class="description"
        >
          <span v-html="group.description">
          </span>
        </div>
      </div>
      <item-stats
        :item="group"
        class="group-stats prepend-top-2"
      />
      <item-actions
        v-if="isGroup"
        :group="group"
        :parent-group="parentGroup"
      />
    </div>
    <group-folder
      v-if="group.isOpen && hasChildren"
      :parent-group="group"
      :groups="group.children"
      :action="action"
    />
  </li>
</template>
