<script>
import { computed } from 'vue';
import {
  GlLoadingIcon,
  GlButton,
  GlKeysetPagination,
  GlLink,
  GlBadge,
  GlTab,
  GlTabs,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  INSTRUMENT_TAB_LABELS,
  INSTRUMENT_TODO_FILTER_CHANGE,
  STATUS_BY_TAB,
  TAB_PENDING,
  TODO_WAIT_BEFORE_RELOAD,
} from '~/todos/constants';
import getTodosQuery from './queries/get_todos.query.graphql';
import getPendingTodosCount from './queries/get_pending_todos_count.query.graphql';
import TodoItem from './todo_item.vue';
import TodosEmptyState from './todos_empty_state.vue';
import TodosFilterBar, { SORT_OPTIONS } from './todos_filter_bar.vue';
import TodosMarkAllDoneButton from './todos_mark_all_done_button.vue';

const ENTRIES_PER_PAGE = 20;

export default {
  components: {
    GlLink,
    GlButton,
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
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  provide() {
    return {
      currentTab: computed(() => this.currentTab),
    };
  },
  data() {
    return {
      updatePid: null,
      needsRefresh: false,
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
      pendingTodosCount: '-',
      queryFilterValues: {
        groupId: [],
        projectId: [],
        authorId: [],
        type: [],
        action: [],
        sort: `${SORT_OPTIONS[0].value}_DESC`,
      },
      alert: null,
      showSpinnerWhileLoading: true,
    };
  },
  apollo: {
    todos: {
      query: getTodosQuery,
      fetchPolicy: 'cache-and-network',
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
      watchLoading() {
        // We reset the `needsRefresh` when paginating or changing tabs
        this.needsRefresh = false;
      },
    },
    pendingTodosCount: {
      query: getPendingTodosCount,
      variables() {
        return this.queryFilterValues;
      },
      update({ currentUser: { todos: { count } } = {} }) {
        return count;
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
      return this.currentTab === TAB_PENDING && !this.showEmptyState;
    },
  },
  mounted() {
    document.addEventListener('visibilitychange', this.handleVisibilityChanged);
  },
  beforeDestroy() {
    document.removeEventListener('visibilitychange', this.handleVisibilityChanged);
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
      this.track(INSTRUMENT_TODO_FILTER_CHANGE, {
        label: INSTRUMENT_TAB_LABELS[tabIndex],
      });
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
    handleVisibilityChanged() {
      if (!document.hidden) {
        this.updateAllQueries(false);
      }
    },
    async handleItemChanged() {
      this.needsRefresh = true;

      await this.updateCounts();
    },
    updateCounts() {
      return this.$apollo.queries.pendingTodosCount.refetch();
    },
    async updateAllQueries(showLoading = true) {
      this.$root.$emit('bv::hide::tooltip', 'todo-refresh-btn');
      this.showSpinnerWhileLoading = showLoading;

      await Promise.all([this.updateCounts(), this.$apollo.queries.todos.refetch()]);

      this.showSpinnerWhileLoading = true;
    },
    markInteracting() {
      clearTimeout(this.updatePid);
    },
    stoppedInteracting() {
      if (!this.needsRefresh) {
        return;
      }

      if (this.updatePid) {
        clearTimeout(this.updatePid);
      }

      this.updatePid = setTimeout(() => {
        /*
         We double-check needsRefresh or
         whether a query is already running
         */
        if (this.needsRefresh && !this.$apollo.queries.todos.loading) {
          this.updateAllQueries(false);
        }
        this.updatePid = null;
      }, TODO_WAIT_BEFORE_RELOAD);
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
            <gl-badge pill size="sm" class="gl-tab-counter-badge" data-testid="pending-todos-count">
              {{ pendingTodosCount }}
            </gl-badge>
          </template>
        </gl-tab>
        <gl-tab>
          <template #title>
            <span>{{ s__('Todos|Done') }}</span>
          </template>
        </gl-tab>
        <gl-tab>
          <template #title>
            <span>{{ s__('Todos|All') }}</span>
          </template>
        </gl-tab>
      </gl-tabs>

      <div class="gl-my-3 gl-mr-5 gl-flex gl-items-center gl-justify-end gl-gap-3">
        <todos-mark-all-done-button
          v-if="showMarkAllAsDone"
          :filters="queryFilterValues"
          @change="updateAllQueries"
        />

        <gl-button
          id="todo-refresh-btn"
          v-gl-tooltip.hover
          data-testid="refresh-todos"
          icon="retry"
          :aria-label="__('Refresh')"
          :title="__('Refresh')"
          :loading="isLoading && !showSpinnerWhileLoading"
          @click.prevent="updateAllQueries(false)"
        />
      </div>
    </div>

    <todos-filter-bar :todos-status="statusByTab" @filters-changed="handleFiltersChanged" />

    <div>
      <div class="gl-flex gl-flex-col">
        <gl-loading-icon v-if="isLoading && showSpinnerWhileLoading" size="lg" class="gl-mt-5" />
        <ul
          v-else
          data-testid="todo-item-list-container"
          class="gl-m-0 gl-border-collapse gl-list-none gl-p-0"
          @mouseenter="markInteracting"
          @mouseleave="stoppedInteracting"
        >
          <transition-group name="todos">
            <todo-item
              v-for="todo in todos"
              :key="todo.id"
              :todo="todo"
              :current-user-id="currentUserId"
              @change="handleItemChanged"
            />
          </transition-group>
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

<style>
.todos-leave-active {
  transition: transform 0.15s ease-out;
  position: absolute;
}
.todos-leave-to {
  opacity: 0;
  transform: translateY(-100px);
}
.todos-move {
  transition: transform 0.15s ease-out;
}
</style>
