<script>
import identicon from '../../vue_shared/components/identicon.vue';
import eventHub from '../event_hub';

import itemCaret from './item_caret.vue';
import itemTypeIcon from './item_type_icon.vue';
import itemStats from './item_stats.vue';
import itemActions from './item_actions.vue';

export default {
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
          gl.utils.visitUrl(this.group.relativePath);
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
      class="group-row-contents">
      <item-actions
        v-if="isGroup"
        :group="group"
        :parent-group="parentGroup"
      />
      <item-stats
        :item="group"
      />
      <div
        class="folder-toggle-wrap">
        <item-caret
          :is-group-open="group.isOpen"
        />
        <item-type-icon
          :item-type="group.type"
          :is-group-open="group.isOpen"
        />
      </div>
      <div
        class="avatar-container s40 hidden-xs"
        :class="{ 'content-loading': group.isChildrenLoading }"
      >
        <a
          :href="group.relativePath"
          class="no-expand"
        >
          <img
            v-if="hasAvatar"
            class="avatar s40"
            :src="group.avatarUrl"
          />
          <identicon
            v-else
            :entity-id=group.id
            :entity-name="group.name"
          />
        </a>
      </div>
      <div
        class="title">
        <a
          :href="group.relativePath"
          class="no-expand">{{group.fullName}}</a>
        <span
          v-if="group.permission"
          class="access-type"
        >
          {{s__('GroupsTreeRole|as')}} {{group.permission}}
        </span>
      </div>
      <div
        class="description">{{group.description}}</div>
    </div>
    <group-folder
      v-if="group.isOpen && hasChildren"
      :parent-group="group"
      :groups="group.children"
    />
  </li>
</template>
