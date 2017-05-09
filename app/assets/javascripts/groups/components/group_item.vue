<script>
import eventHub from '../event_hub';

export default {
  name: 'group-item',
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  methods: {
    toggleSubGroups() {
      if (!this.group.subGroups.length) {
        return;
      }

      eventHub.$emit('toggleSubGroups', this.group);
    },
  },
};
</script>

<template>
  <tr @click="toggleSubGroups">
    <td>
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
      <span>
        <a :href="group.web_url">{{group.full_name}}</a>
      </span>
    </td>
  </tr>
</template>
