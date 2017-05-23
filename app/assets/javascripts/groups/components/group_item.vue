<script>
import eventHub from '../event_hub';

export default {
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  methods: {
    toggleSubGroups(e) {
      if (e.target.tagName === 'A') {
        return false;
      }

      // TODO: Do not trigger if group will not have subgroups

      return eventHub.$emit('toggleSubGroups', this.group);
    },
  },
  computed: {
    rowClass() {
      return {
        'group-row': true,
        'is-open': this.group.isOpen,
        'is-expandable': this.isExpandable,
        'no-description': !this.group.description,
      };
    },
    isExpandable() {
      return Object.keys(this.group.subGroups).length > 0;
    },
  },
};
</script>

<template>
  <li
    @click.stop="toggleSubGroups"
    :id="group.id"
    :class="rowClass"
    >
    <div class="controls">
      <a class="btn" href="#edit">
        <i aria-hidden="true" class="fa fa-cogs"></i>
      </a>
      <a class="btn" title="Leave this group" href="#leave">
        <i aria-hidden="true" class="fa fa-sign-out"></i>
      </a>
    </div>

    <div class="stats">
      <span >
        <i aria-hidden="true" class="fa fa-bookmark"></i>
        {{group.numberProjects}}
      </span>
      <span>
        <i aria-hidden="true" class="fa fa-users"></i>
        {{group.numberMembers}}
      </span>
      <span>
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
      <a :href="group.webUrl">{{group.isOrphan ? group.fullName : group.name}}</a>
    </div>

    <div class="description">
      {{group.description}}
    </div>

    <group-folder v-if="group.isOpen" :groups="group.subGroups" />
  </li>
</template>
