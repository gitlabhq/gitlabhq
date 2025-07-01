<script>
import { computed } from 'vue';
import { GlButton, GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import emptyTodosAllDoneSvg from '@gitlab/svgs/dist/illustrations/status/status-success-sm.svg';
import emptyTodosFilteredSvg from '@gitlab/svgs/dist/illustrations/search-sm.svg';
import { s__ } from '~/locale';
import {
  TABS_INDICES,
  TODO_ACTION_TYPE_BUILD_FAILED,
  TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_ACTION_TYPE_MENTIONED,
  TODO_ACTION_TYPE_REVIEW_REQUESTED,
  TODO_ACTION_TYPE_UNMERGEABLE,
} from '~/todos/constants';
import TodoItem from '~/todos/components/todo_item.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const N_TODOS = 5;

const FILTER_OPTIONS = [
  {
    value: null,
    text: s__('Todos|All'),
  },
  {
    value: TODO_ACTION_TYPE_ASSIGNED,
    text: s__('Todos|Assigned'),
  },
  {
    value: `${TODO_ACTION_TYPE_MENTIONED};${TODO_ACTION_TYPE_DIRECTLY_ADDRESSED}`,
    text: s__('Todos|Mentioned'),
  },
  {
    value: TODO_ACTION_TYPE_BUILD_FAILED,
    text: s__('Todos|Build failed'),
  },
  {
    value: TODO_ACTION_TYPE_UNMERGEABLE,
    text: s__('Todos|Unmergeable'),
  },
  {
    value: TODO_ACTION_TYPE_REVIEW_REQUESTED,
    text: s__('Todos|Review requested'),
  },
];

export default {
  components: { TodoItem, GlButton, GlCollapsibleListbox },
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
      filter: null,
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
          action: this.filter ? this.filter.split(';') : null,
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
  emptyTodosAllDoneSvg,
  emptyTodosFilteredSvg,
  FILTER_OPTIONS,
};
</script>

<template>
  <div>
    <div class="gl-flex gl-items-center gl-justify-between gl-gap-2">
      <h4 class="gl-grow">{{ __('To-do items') }}</h4>

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

      <gl-collapsible-listbox v-model="filter" :items="$options.FILTER_OPTIONS" />
    </div>

    <div
      v-if="!$apollo.queries.todos.loading && !todos.length && !filter"
      class="gl-flex gl-items-center gl-gap-5 gl-bg-subtle gl-p-4"
    >
      <img class="gl-h-11" aria-hidden="true" :src="$options.emptyTodosAllDoneSvg" />
      <span>
        <strong>{{ __('Good job!') }}</strong>
        {{ __('All your to-do items are done.') }}
      </span>
    </div>
    <div
      v-else-if="!$apollo.queries.todos.loading && !todos.length && filter"
      class="gl-flex gl-items-center gl-gap-5 gl-bg-subtle gl-p-4"
    >
      <img class="gl-h-11" aria-hidden="true" :src="$options.emptyTodosFilteredSvg" />
      <span>{{ __('Sorry, your filter produced no results') }}</span>
    </div>
    <div v-else>
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
  </div>
</template>
