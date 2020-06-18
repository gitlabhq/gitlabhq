<script>
import Todo from '~/sidebar/components/todo_toggle/todo.vue';

export default {
  components: {
    Todo,
  },
  props: {
    sidebarCollapsed: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<!-- TODO: Implement after or as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/215946 -->
<template>
  <div v-if="false" :class="{ 'block todo': sidebarCollapsed }">
    <todo
      :collapsed="sidebarCollapsed"
      :issuable-id="1"
      :is-todo="false"
      :is-action-active="false"
      issuable-type="alert"
      @toggleTodo="() => {}"
    />
  </div>
</template>
