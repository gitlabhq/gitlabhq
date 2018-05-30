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
      if (!(e.target.classList.contains(NO_EXPAND_CLS) ||
            e.target.parentElement.classList.contains(NO_EXPAND_CLS))) {
        if (this.hasChildren) {
          eventHub.$emit('toggleChildren', this.group);
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
    @click.stop="onClickRowGroup"
    :id="groupDomId"
    :class="rowClass"
    class="group-row"
  >
    <div
      class="group-row-contents"
      :class="{ 'project-row-contents': !isGroup }">
      <item-actions
        v-if="isGroup"
        :group="group"
        :parent-group="parentGroup"
      />
      <item-stats
        :item="group"
      />
      <div
        class="folder-toggle-wrap"
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
        class="avatar-container prepend-top-8 prepend-left-5 s24 d-none d-sm-block"
        :class="{ 'content-loading': group.isChildrenLoading }"
      >
        <a
          :href="group.relativePath"
          class="no-expand"
        >
          <img
            v-if="hasAvatar"
            class="avatar s24"
            :src="group.avatarUrl"
          />
          <identicon
            v-else
            size-class="s24"
            :entity-id="group.id"
            :entity-name="group.name"
          />
        </a>
      </div>
      <div
        class="title namespace-title"
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
        class="description">
        <span v-html="group.description">
        </span>
      </div>
    </div>
    <group-folder
      v-if="group.isOpen && hasChildren"
      :parent-group="group"
      :groups="group.children"
    />
  </li>
</template>
