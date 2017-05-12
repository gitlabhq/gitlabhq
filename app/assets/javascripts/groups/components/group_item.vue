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
      eventHub.$emit('toggleSubGroups', this.group);
    },
  },
};
</script>

<template>
  <li
    @click="toggleSubGroups" class="list-group-item"
    :id="group.id"
    >
    <span v-show="group.expandable">
      <i
        v-show="group.isOpen"
        class="fa fa-caret-down"
        aria-hidden="true" />
      <i
        v-show="!group.isOpen"
        class="fa fa-caret-right"
        aria-hidden="true"/>
    </span>

    <code>{{group.id}}</code> - <code v-show="group.isOrphan">Orphan</code> <a :href="group.webUrl">{{group.fullName}}</a></span>
    <span>{{group.description}}</span>

    <group-folder v-if="group.isOpen" :groups="group.subGroups" />
  </li>
</template>
