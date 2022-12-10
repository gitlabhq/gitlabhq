<script>
import RunnerAssignedItem from './runner_assigned_item.vue';

export default {
  components: {
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
  <div class="gl-border-t-gray-100 gl-border-t-1 gl-border-t-solid">
    <h3 class="gl-font-lg gl-mt-5 gl-mb-0">{{ s__('Runners|Assigned Group') }}</h3>
    <template v-if="groups.length">
      <runner-assigned-item
        v-for="group in groups"
        :key="group.id"
        :href="group.webUrl"
        :name="group.name"
        :full-name="group.fullName"
        :avatar-url="group.avatarUrl"
      />
    </template>
    <span v-else class="gl-text-secondary">{{ __('None') }}</span>
  </div>
</template>
