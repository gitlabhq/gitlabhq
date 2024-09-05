<script>
import { GlLoadingIcon, GlKeysetPagination, GlButton, GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import getTodosQuery from './queries/get_todos.query.graphql';
import getTodosCountQuery from './queries/get_todos_count.query.graphql';
import TodoItem from './todo_item.vue';
import TodosFilterBar, { SORT_OPTIONS } from './todos_filter_bar.vue';

const ENTRIES_PER_PAGE = 20;
const STATUS_BY_TAB = [['pending'], ['done'], ['pending', 'done']];

export default {
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    GlButton,
    GlBadge,
    GlTabs,
    GlTab,
    TodosFilterBar,
    TodoItem,
  },

  data() {
    return {
      cursor: {
        first: ENTRIES_PER_PAGE,
        after: null,
        last: null,
        before: null,
      },
      currentUserId: null,
      pageInfo: {},
      todos: [],
      currentTab: 0,
      todosCount: {
        pending: 0,
        done: 0,
        all: 0,
      },
      queryFilterValues: {
        groupId: [],
        projectId: [],
        type: [],
        action: [],
        sort: `${SORT_OPTIONS[0].value}_DESC`,
      },
    };
  },
  apollo: {
    todos: {
      query: getTodosQuery,
      variables() {
        return {
          state: STATUS_BY_TAB[this.currentTab],
          ...this.queryFilterValues,
          ...this.cursor,
        };
      },
      update({ currentUser: { id, todos: { nodes = [], pageInfo = {} } } = {} }) {
        this.pageInfo = pageInfo;
        this.currentUserId = id;
        return nodes;
      },
      error(error) {
        createAlert({ message: s__('Todos|Something went wrong. Please try again.') });
        Sentry.captureException(error);
      },
    },
    todosCount: {
      query: getTodosCountQuery,
      variables() {
        return this.queryFilterValues;
      },
      update({
        currentUser: {
          pending: { count: pending },
          done: { count: done },
          all: { count: all },
        } = {},
      }) {
        return {
          pending,
          done,
          all,
        };
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.todos.loading;
    },
    showPagination() {
      return !this.isLoading && (this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage);
    },
    showMarkAllAsDone() {
      return this.currentTab === 0;
    },
    fadeDoneTodo() {
      return this.currentTab === 0;
    },
  },
  methods: {
    nextPage(item) {
      this.cursor = {
        first: ENTRIES_PER_PAGE,
        after: item,
        last: null,
        before: null,
      };
    },
    prevPage(item) {
      this.cursor = {
        first: null,
        after: null,
        last: ENTRIES_PER_PAGE,
        before: item,
      };
    },
    tabChanged(tabIndex) {
      this.currentTab = tabIndex;
      this.cursor = {
        first: ENTRIES_PER_PAGE,
        after: null,
        last: null,
        before: null,
      };
    },
    handleFiltersChanged(data) {
      this.queryFilterValues = { ...data };
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-justify-between gl-border-b-1 gl-border-gray-100 gl-border-b-solid">
      <gl-tabs content-class="gl-p-0" nav-class="gl-border-0" @input="tabChanged">
        <gl-tab>
          <template #title>
            <span>{{ s__('Todos|To Do') }}</span>
            <gl-badge pill size="sm" class="gl-tab-counter-badge">
              {{ todosCount.pending }}
            </gl-badge>
          </template>
        </gl-tab>
        <gl-tab>
          <template #title>
            <span>{{ s__('Todos|Done') }}</span>
            <gl-badge pill size="sm" class="gl-tab-counter-badge"> {{ todosCount.done }} </gl-badge>
          </template>
        </gl-tab>
        <gl-tab>
          <template #title>
            <span>{{ s__('Todos|All') }}</span>
            <gl-badge pill size="sm" class="gl-tab-counter-badge"> {{ todosCount.all }} </gl-badge>
          </template>
        </gl-tab>
      </gl-tabs>

      <div v-if="showMarkAllAsDone" class="gl-my-3 gl-mr-5 gl-flex gl-items-center gl-justify-end">
        <gl-button data-testid="btn-mark-all-as-done">
          {{ s__('Todos|Mark all as done') }}
        </gl-button>
      </div>
    </div>

    <todos-filter-bar @filters-changed="handleFiltersChanged" />

    <div>
      <div class="gl-flex gl-flex-col">
        <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
        <ul v-else class="gl-m-0 gl-border-collapse gl-list-none gl-p-0">
          <todo-item
            v-for="todo in todos"
            :key="todo.id"
            :todo="todo"
            :current-user-id="currentUserId"
            :fade-done-todo="fadeDoneTodo"
          />
        </ul>
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          class="gl-mt-3 gl-self-center"
          @prev="prevPage"
          @next="nextPage"
        />
      </div>
    </div>
  </div>
</template>
