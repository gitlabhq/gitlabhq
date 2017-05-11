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
    toggleSubGroups() {
      if (!this.group.subGroups || (this.group.subGroups && !this.group.subGroups.length)) {
        return;
      }

      eventHub.$emit('toggleSubGroups', this.group);
    },
  },
};
</script>

<template>
  <li @click="toggleSubGroups" class="list-group-item">
    <span v-show="group.subGroups && group.subGroups.length">
      <i
        v-show="group.isOpen"
        class="fa fa-caret-down"
        aria-hidden="true" />
      <i
        v-show="!group.isOpen"
        class="fa fa-caret-right"
        aria-hidden="true"/>
    </span>

    <p><a :href="group.web_url">{{group.full_name}}</a></p>
    <p>{{group.description}}</p>

    <group-folder v-if="group.subGroups && group.isOpen" :groups="group.subGroups" />
  </li>
</template>
