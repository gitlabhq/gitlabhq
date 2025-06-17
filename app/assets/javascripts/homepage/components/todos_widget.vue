<script>
import { computed } from 'vue';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { TABS_INDICES } from '~/todos/constants';
import TodoItem from '~/todos/components/todo_item.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const N_TODOS = 5;

export default {
  components: { TodoItem, GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  provide() {
    return {
      currentTab: TABS_INDICES.pending,
      currentTime: new Date(),
      currentUserId: computed(() => this.currentUserId),
    };
  },
  data() {
    return {
      currentUserId: null,
      todos: [],
    };
  },
  apollo: {
    todos: {
      query: getTodosQuery,
      variables() {
        return {
          first: N_TODOS,
          state: ['pending'],
        };
      },
      update({ currentUser: { id, todos: { nodes = [] } } = {} }) {
        this.currentUserId = id;

        return nodes;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-items-center gl-justify-between gl-gap-2">
      <h4>{{ __('Latest to-do items') }}</h4>

      <gl-button
        v-gl-tooltip.hover
        icon="retry"
        :aria-label="__('Refresh')"
        :title="__('Refresh')"
        :loading="$apollo.queries.todos.loading"
        category="tertiary"
        size="small"
        @click="$apollo.queries.todos.refetch()"
      />
    </div>

    <todo-item
      v-for="todo in todos"
      :key="todo.id"
      :todo="todo"
      @change="$apollo.queries.todos.refetch()"
    />
    <div class="gl-p-3">
      <a href="/dashboard/todos">{{ __('All to-do items') }}</a>
    </div>
  </div>
</template>
