<script>
import { GlLoadingIcon, GlKeysetPagination, GlLink, GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import getTodosQuery from './queries/get_todos.query.graphql';
import getTodosCountQuery from './queries/get_todos_count.query.graphql';
import TodoItem from './todo_item.vue';
import TodosEmptyState from './todos_empty_state.vue';
import TodosFilterBar, { SORT_OPTIONS } from './todos_filter_bar.vue';
import TodosMarkAllDoneButton from './todos_mark_all_done_button.vue';

const ENTRIES_PER_PAGE = 20;
const STATUS_BY_TAB = [['pending'], ['done'], ['pending', 'done']];

export default {
  components: {
    GlLink,
    GlLoadingIcon,
    GlKeysetPagination,
    GlBadge,
    GlTabs,
    GlTab,
    TodosEmptyState,
    TodosFilterBar,
    TodoItem,
    TodosMarkAllDoneButton,
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
        pending: '-',
        done: '-',
        all: '-',
      },
      queryFilterValues: {
        groupId: [],
        projectId: [],
        authorId: [],
        type: [],
        action: [],
        sort: `${SORT_OPTIONS[0].value}_DESC`,
      },
      alert: null,
    };
  },
  apollo: {
    todos: {
      query: getTodosQuery,
      variables() {
        return {
          state: this.statusByTab,
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
        this.alert = createAlert({ message: s__('Todos|Something went wrong. Please try again.') });
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
    statusByTab() {
      return STATUS_BY_TAB[this.currentTab];
    },
    isLoading() {
      return this.$apollo.queries.todos.loading;
    },
    isFiltered() {
      // Ignore sort value. It is always present and not really a filter.
      const { sort: _, ...filters } = this.queryFilterValues;
      return Object.values(filters).some((value) => value.length > 0);
    },
    showPagination() {
      return !this.isLoading && (this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage);
    },
    showEmptyState() {
      return !this.isLoading && this.todos.length === 0;
    },
    showMarkAllAsDone() {
      return this.currentTab === 0 && !this.showEmptyState;
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
      this.alert?.dismiss();
      this.queryFilterValues = { ...data };
    },
    updateCounts() {
      this.$apollo.queries.todosCount.refetch();
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
        <todos-mark-all-done-button @change="updateCounts" />
      </div>
    </div>

    <todos-filter-bar :todos-status="statusByTab" @filters-changed="handleFiltersChanged" />

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

        <todos-empty-state v-if="showEmptyState" :is-filtered="isFiltered" />

        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          class="gl-mt-3 gl-self-center"
          @prev="prevPage"
          @next="nextPage"
        />

        <div class="gl-mt-5 gl-text-center">
          <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/498315" target="_blank">{{
            s__('Todos|Leave feedback')
          }}</gl-link>
        </div>
      </div>
    </div>
  </div>
</template>
