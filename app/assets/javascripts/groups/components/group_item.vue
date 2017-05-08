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
  <tr @click="toggleSubGroups">
    <template >
      <td>
        <span>
          <i
            v-show="group.isOpen"
            class="fa fa-caret-down"
            aria-hidden="true" />
          <i
            v-show="!group.isOpen"
            class="fa fa-caret-right"
            aria-hidden="true"/>
        </span>
      </td>
      <td>
        <div>
          <a :href="group.web_url">{{group.full_name}}</a>
        </div>
        <div>{{group.description}}</div>
      </td>
    </template>
  </tr>
</template>
