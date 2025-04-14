<script>
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import RunnerAssignedItem from './runner_assigned_item.vue';

export default {
  components: {
    CrudComponent,
    RunnerAssignedItem,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    groups() {
      return this.runner.groups?.nodes || [];
    },
  },
};
</script>

<template>
  <crud-component
    v-if="groups.length"
    :title="s__('Runners|Assigned Group')"
    data-testid="runner-groups"
  >
    <ul class="content-list">
      <runner-assigned-item
        v-for="group in groups"
        :key="group.id"
        :href="group.webUrl"
        :name="group.name"
        :full-name="group.fullName"
        :avatar-url="group.avatarUrl"
      />
    </ul>
  </crud-component>
</template>
