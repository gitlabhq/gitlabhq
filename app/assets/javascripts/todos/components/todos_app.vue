<script>
import { computed } from 'vue';
import {
  GlButton,
  GlLoadingIcon,
  GlLink,
  GlBadge,
  GlTab,
  GlTabs,
  GlTooltipDirective,
  GlFormCheckbox,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  DEFAULT_PAGE_SIZE,
  INSTRUMENT_TAB_LABELS,
  INSTRUMENT_TODO_FILTER_CHANGE,
  STATUS_BY_TAB,
  TODO_WAIT_BEFORE_RELOAD,
  TABS_INDICES,
} from '~/todos/constants';
import getTodosQuery from './queries/get_todos.query.graphql';
import getPendingTodosCount from './queries/get_pending_todos_count.query.graphql';
import TodoItem from './todo_item.vue';
import TodosEmptyState from './todos_empty_state.vue';
import TodosFilterBar, { SORT_OPTIONS } from './todos_filter_bar.vue';
import TodosMarkAllDoneButton from './todos_mark_all_done_button.vue';
import TodosBulkBar from './todos_bulk_bar.vue';
import TodosPagination from './todos_pagination.vue';

export default {
  components: {
    GlLink,
    GlButton,
    GlLoadingIcon,
    GlBadge,
    GlTabs,
    GlTab,
    GlFormCheckbox,
    TodosEmptyState,
    TodosFilterBar,
    TodoItem,
    TodosMarkAllDoneButton,
    TodosBulkBar,
    TodosPagination,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin(), glFeatureFlagMixin()],
  provide() {
    return {
      currentTab: computed(() => this.currentTab),
      currentTime: computed(() => this.currentTime),
    };
  },
  data() {
    return {
      updateTimeoutId: null,
      needsRefresh: false,
      cursor: {
        first: DEFAULT_PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      },
      currentUserId: null,
      pageInfo: {},
      todos: [],
      currentTab: TABS_INDICES.pending,
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
      currentTime: new Date(),
      currentTimeInterval: null,
      multiselectState: {},
      selectAllChecked: false,
    };
  },
  apollo: {
    todos: {
      query: getTodosQuery,
      fetchPolicy: 'cache-and-network',
      variables() {
        const state = this.isOnSnoozedTab ? ['pending'] : this.statusByTab;
        return {
          state,
          ...(this.isOnSnoozedTab ? { isSnoozed: true } : {}),
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
    isLoadingWithSpinner() {
      return this.isLoading && this.showSpinnerWhileLoading;
    },
    isFiltered() {
      // Ignore sort value. It is always present and not really a filter.
      const { sort: _, ...filters } = this.queryFilterValues;
      return Object.values(filters).some((value) => value.length > 0);
    },
    isOnDoneTab() {
      return this.currentTab === TABS_INDICES.done;
    },
    isOnSnoozedTab() {
      return this.currentTab === TABS_INDICES.snoozed;
    },
    isOnAllTab() {
      return this.currentTab === TABS_INDICES.all;
    },
    showEmptyState() {
      return !this.isLoading && this.todos.length === 0;
    },
    showMarkAllAsDone() {
      if (this.glFeatures.todosBulkActions) return false;

      return this.currentTab === TABS_INDICES.pending && !this.showEmptyState;
    },
    showSelectAll() {
      if (!this.glFeatures.todosBulkActions) return false;
      if (this.isOnAllTab) return false;

      return !(this.showEmptyState || this.isLoadingWithSpinner);
    },
    selectedIds() {
      return this.todos.filter((todo) => this.multiselectState[todo.id]).map((todo) => todo.id);
    },
    hasIndeterminateSelectAll() {
      return this.selectedIds.length > 0 && this.selectedIds.length < this.todos.length;
    },
  },
  watch: {
    selectedIds(ids) {
      if (!ids.length) this.selectAllChecked = false;
      else if (ids.length === this.todos.length) this.selectAllChecked = true;
    },
  },
  created() {
    const searchParams = new URLSearchParams(window.location.search);
    const stateFromUrl = searchParams.get('state');
    switch (stateFromUrl) {
      case 'snoozed':
        this.currentTab = TABS_INDICES.snoozed;
        break;
      case 'done':
        this.currentTab = TABS_INDICES.done;
        break;
      case 'all':
        this.currentTab = TABS_INDICES.all;
        break;
      default:
        break;
    }
  },
  mounted() {
    document.addEventListener('visibilitychange', this.handleVisibilityChanged);
    this.currentTimeInterval = setInterval(() => {
      this.currentTime = new Date();
    }, 60 * 1000);
  },
  beforeDestroy() {
    document.removeEventListener('visibilitychange', this.handleVisibilityChanged);
    clearInterval(this.currentTimeInterval);
  },
  methods: {
    updateCursor(cursor) {
      this.cursor = cursor;
    },
    tabChanged(tabIndex) {
      if (tabIndex === this.currentTab) {
        return;
      }

      this.unselectAll();

      this.track(INSTRUMENT_TODO_FILTER_CHANGE, {
        label: INSTRUMENT_TAB_LABELS[tabIndex],
      });
      this.currentTab = tabIndex;

      // Use the previous page size, but fetch the first N of the new tab
      this.cursor = {
        first: this.cursor.first || this.cursor.last,
        after: null,
        last: null,
        before: null,
      };
      this.syncActiveTabToUrl();
    },
    syncActiveTabToUrl() {
      const tabIndexToUrlStateParam = {
        [TABS_INDICES.snoozed]: 'snoozed',
        [TABS_INDICES.done]: 'done',
        [TABS_INDICES.all]: 'all',
      };
      const searchParams = new URLSearchParams(window.location.search);
      if (this.currentTab === TABS_INDICES.pending) {
        searchParams.delete('state');
      } else {
        searchParams.set('state', tabIndexToUrlStateParam[this.currentTab]);
      }

      window.history.replaceState(null, '', `?${searchParams.toString()}`);
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
    handleSelectionChanged(id, isSelected) {
      this.multiselectState = {
        ...this.multiselectState,
        [id]: isSelected,
      };
    },
    handleBulkAction() {
      this.unselectAll();
      this.updateAllQueries(false);
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
    startedInteracting() {
      clearTimeout(this.updateTimeoutId);
    },
    stoppedInteracting() {
      if (!this.needsRefresh) {
        return;
      }

      if (this.updateTimeoutId) {
        clearTimeout(this.updateTimeoutId);
      }

      this.updateTimeoutId = setTimeout(() => {
        /*
         We double-check needsRefresh or
         whether a query is already running
         */
        if (this.needsRefresh && !this.$apollo.queries.todos.loading) {
          this.updateAllQueries(false);
        }
        this.updateTimeoutId = null;
      }, TODO_WAIT_BEFORE_RELOAD);
    },
    selectAll() {
      this.multiselectState = Object.fromEntries(this.todos.map((todo) => [todo.id, true]));
    },
    unselectAll() {
      this.multiselectState = {};
      this.selectAllChecked = false;
    },
    handleSelectAllChange(checked) {
      if (checked) this.selectAll();
      else this.unselectAll();
    },
  },
};
</script>

<template>
  <div data-testid="todos-list-container">
    <div
      class="gl-flex gl-flex-wrap-reverse gl-justify-between gl-border-b-1 gl-border-default gl-border-b-solid"
    >
      <gl-tabs
        :value="currentTab"
        content-class="gl-p-0"
        nav-class="gl-border-0"
        @input="tabChanged"
      >
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
            <span>{{ s__('Todos|Snoozed') }}</span>
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

      <div class="gl-my-3 gl-mr-5 gl-flex gl-flex-grow gl-items-center gl-justify-end gl-gap-3">
        <todos-mark-all-done-button
          v-show="showMarkAllAsDone"
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
        <div v-if="showSelectAll" class="gl-flex gl-items-baseline gl-gap-2 gl-px-5 gl-py-3">
          <gl-form-checkbox
            v-model="selectAllChecked"
            data-testid="todos-select-all"
            class="gl-mb-2 gl-mt-3"
            :indeterminate="hasIndeterminateSelectAll"
            @change="handleSelectAllChange"
            >{{
              selectAllChecked ? s__('Todos|Clear all') : s__('Todos|Select all')
            }}</gl-form-checkbox
          >
          <span v-show="selectedIds.length">|</span>
          <todos-bulk-bar
            v-show="selectedIds.length"
            :ids="selectedIds"
            :tab="currentTab"
            @change="handleBulkAction"
          />
        </div>

        <gl-loading-icon v-if="isLoading && showSpinnerWhileLoading" size="lg" class="gl-mt-5" />
        <div
          v-else
          data-testid="todo-item-list-container"
          @mouseenter="startedInteracting"
          @mouseleave="stoppedInteracting"
        >
          <transition-group
            name="todos"
            tag="ol"
            data-testid="todo-item-list"
            class="gl-m-0 gl-list-none gl-p-0"
          >
            <todo-item
              v-for="todo in todos"
              :key="todo.id"
              :todo="todo"
              :current-user-id="currentUserId"
              :selected="selectedIds.includes(todo.id)"
              @change="handleItemChanged"
              @select-change="handleSelectionChanged"
            />
          </transition-group>
        </div>

        <todos-empty-state v-if="showEmptyState" :is-filtered="isFiltered" />

        <todos-pagination v-if="!showEmptyState" v-bind="pageInfo" @cursor-changed="updateCursor" />

        <div class="gl-mt-5 gl-text-center">
          <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/506387" target="_blank">{{
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
