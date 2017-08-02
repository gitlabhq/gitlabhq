<script>
import eventHub from '../event_hub';
import groupIdenticon from './group_identicon.vue';

export default {
  components: {
    groupIdenticon,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    baseGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    collection: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  methods: {
    onClickRowGroup(e) {
      e.stopPropagation();

      // Skip for buttons
      if (!(e.target.tagName === 'A') && !(e.target.tagName === 'I' && e.target.parentElement.tagName === 'A')) {
        if (this.group.hasSubgroups) {
          eventHub.$emit('toggleSubGroups', this.group);
        } else {
          window.location.href = this.group.groupPath;
        }
      }
    },
    onLeaveGroup(e) {
      e.preventDefault();

      // eslint-disable-next-line no-alert
      if (confirm(`Are you sure you want to leave the "${this.group.fullName}" group?`)) {
        this.leaveGroup();
      }
    },
    leaveGroup() {
      eventHub.$emit('leaveGroup', this.group, this.collection);
    },
  },
  computed: {
    groupDomId() {
      return `group-${this.group.id}`;
    },
    rowClass() {
      return {
        'group-row': true,
        'is-open': this.group.isOpen,
        'has-subgroups': this.group.hasSubgroups,
        'no-description': !this.group.description,
      };
    },
    visibilityIcon() {
      return {
        fa: true,
        'fa-globe': this.group.visibility === 'public',
        'fa-shield': this.group.visibility === 'internal',
        'fa-lock': this.group.visibility === 'private',
      };
    },
    fullPath() {
      let fullPath = '';

      if (this.group.isOrphan) {
        // check if current group is baseGroup
        if (Object.keys(this.baseGroup).length > 0 && this.baseGroup !== this.group) {
          // Remove baseGroup prefix from our current group.fullName. e.g:
          // baseGroup.fullName: `level1`
          // group.fullName: `level1 / level2 / level3`
          // Result: `level2 / level3`
          const gfn = this.group.fullName;
          const bfn = this.baseGroup.fullName;
          const length = bfn.length;
          const start = gfn.indexOf(bfn);
          const extraPrefixChars = 3;

          fullPath = gfn.substr(start + length + extraPrefixChars);
        } else {
          fullPath = this.group.fullName;
        }
      } else {
        fullPath = this.group.name;
      }

      return fullPath;
    },
    hasGroups() {
      return Object.keys(this.group.subGroups).length > 0;
    },
    hasAvatar() {
      return this.group.avatarUrl && this.group.avatarUrl.indexOf('/assets/no_group_avatar') === -1;
    },
  },
};
</script>

<template>
  <li
    @click.stop="onClickRowGroup"
    :id="groupDomId"
    :class="rowClass"
    >
    <div
      class="group-row-contents">
      <div
        class="controls">
        <a
          v-if="group.canEdit"
          class="edit-group btn"
          :href="group.editPath">
          <i
            class="fa fa-cogs"
            aria-hidden="true"
          >
          </i>
        </a>
        <a
          @click="onLeaveGroup"
          :href="group.leavePath"
          class="leave-group btn"
          title="Leave this group">
          <i
            class="fa fa-sign-out"
            aria-hidden="true"
          >
          </i>
        </a>
      </div>
      <div
        class="stats">
        <span
          class="number-projects">
          <i
            class="fa fa-bookmark"
            aria-hidden="true"
          >
          </i>
          {{group.numberProjects}}
        </span>
        <span
          class="number-users">
          <i
            class="fa fa-users"
            aria-hidden="true"
          >
          </i>
          {{group.numberUsers}}
        </span>
        <span
          class="group-visibility">
          <i
            :class="visibilityIcon"
            aria-hidden="true"
          >
          </i>
        </span>
      </div>
      <div
        class="folder-toggle-wrap">
        <span
          class="folder-caret"
          v-if="group.hasSubgroups">
          <i
            v-if="group.isOpen"
            class="fa fa-caret-down"
            aria-hidden="true"
          >
          </i>
          <i
            v-if="!group.isOpen"
            class="fa fa-caret-right"
            aria-hidden="true"
          >
          </i>
        </span>
        <span class="folder-icon">
          <i
            v-if="group.isOpen"
            class="fa fa-folder-open"
            aria-hidden="true"
          >
          </i>
          <i
            v-if="!group.isOpen"
            class="fa fa-folder"
            aria-hidden="true">
          </i>
        </span>
      </div>
      <div
        class="avatar-container s40 hidden-xs">
        <a
          :href="group.groupPath">
          <img
            v-if="hasAvatar"
            class="avatar s40"
            :src="group.avatarUrl"
          />
          <group-identicon
            v-else
            :entity-id=group.id
            :entity-name="group.name"
          />
        </a>
      </div>
      <div
        class="title">
        <a
          :href="group.groupPath">{{fullPath}}</a>
        <template v-if="group.permissions.humanGroupAccess">
        as
        <span class="access-type">{{group.permissions.humanGroupAccess}}</span>
        </template>
      </div>
      <div
        class="description">{{group.description}}</div>
    </div>
    <group-folder
      v-if="group.isOpen && hasGroups"
      :groups="group.subGroups"
      :baseGroup="group"
    />
  </li>
</template>
