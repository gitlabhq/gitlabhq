<script>
/* eslint-disable no-alert */

import eventHub from '../event_hub';

export default {
  props: {
    group: {
      type: Object,
      required: true,
    },
    baseGroup: {
      type: Object,
      required: false,
    },
  },
  methods: {
    onClickRowGroup(e) {
      // e.stopPropagation();

      // Skip for buttons
      if (e.target.tagName === 'A' ||
        (e.target.tagName === 'I' && e.target.parentElement.tagName === 'A')) {
      } else {
        if (this.group.hasSubgroups) {
          eventHub.$emit('toggleSubGroups', this.group);
        } else {
          window.location.href = this.group.webUrl;
        }
      }

      return false;
    },
    onLeaveGroup(e) {
      e.preventDefault();

      if (confirm(`Are you sure you want to leave the "${this.group.fullName}" group?`)) {
        this.leaveGroup();
      }

      return false;
    },
    leaveGroup() {
      eventHub.$emit('leaveGroup', this.group.leavePath);
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
    fullPath() {
      let fullPath = '';

      if (this.group.isOrphan) {
        // check if current group is baseGroup
        if (this.baseGroup) {
          // Remove baseGroup prefix from our current group.fullName. e.g:
          // baseGroup.fullName: `level1`
          // group.fullName: `level1 / level2 / level3`
          // Result: `level2 / level3`
          const gfn = this.group.fullName;
          const bfn = this.baseGroup.fullName;
          const length = bfn.length;
          const start = gfn.indexOf(bfn);

          fullPath = gfn.substr(start + length + 3);
        } else {
          fullPath = this.group.fullName;
        }
      } else {
        fullPath = this.group.name;
      }

      return fullPath;
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
    <div class="controls">
      <a
        v-show="group.canEdit"
        class="edit-group btn"
        :href="group.editPath">
        <i aria-hidden="true" class="fa fa-cogs"></i>
      </a>
      <a @click="onLeaveGroup"
        :href="group.leavePath"
        class="leave-group btn"
        title="Leave this group">
        <i aria-hidden="true" class="fa fa-sign-out"></i>
      </a>
    </div>

    <div class="stats">
      <span class="number-projects">
        <i aria-hidden="true" class="fa fa-bookmark"></i>
        {{group.numberProjects}}
      </span>
      <span class="number-users">
        <i aria-hidden="true" class="fa fa-users"></i>
        {{group.numberUsers}}
      </span>
      <span class="group-visibility">
        <i aria-hidden="true" class="fa fa-globe"></i>
      </span>
    </div>

    <div class="folder-toggle-wrap">
      <span class="folder-caret">
        <i
          v-show="group.isOpen"
          class="fa fa-caret-down" />
        <i
          v-show="!group.isOpen"
          class="fa fa-caret-right" />
      </span>

      <span class="folder-icon">
        <i
          v-show="group.isOpen"
          class="fa fa-folder-open"
          aria-hidden="true" />
        <i
          v-show="!group.isOpen"
          class="fa fa-folder" />
      </span>
    </div>

    <div class="avatar-container s40">
      <a href="/h5bp">
        <img class="avatar s40 hidden-xs" src="http://localhost:3000/uploads/group/avatar/2/logo-extra-whitespace.png" alt="Logo extra whitespace">
      </a>
    </div>

    <div class="title">
      <a :href="group.webUrl">{{fullPath}}</a>
    </div>

    <div class="description">
      {{group.description}}
    </div>

    <group-folder v-if="group.isOpen" :groups="group.subGroups" :baseGroup="group" />
  </li>
</template>
