<script>
import { computed } from 'vue';
import { GlBadge, GlTab, GlTabs, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import emptyTodosAllDoneSvg from '@gitlab/svgs/dist/illustrations/status/status-success-sm.svg';
import emptyTodosFilteredSvg from '@gitlab/svgs/dist/illustrations/search-sm.svg';
import { n__, s__, sprintf } from '~/locale';
import { InternalEvents } from '~/tracking';
import { dashboardTodosPath } from '~/lib/utils/path_helpers/dashboard';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  TODO_ACTION_TYPE_BUILD_FAILED,
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_ACTION_TYPE_REVIEW_REQUESTED,
  TODO_ACTION_TYPE_REVIEW_SUBMITTED,
  TODO_ACTION_TYPE_UNMERGEABLE,
} from '~/todos/constants';
import TodoItem from '~/todos/components/todo_item.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import getTodosCountsQuery from '../graphql/queries/todos_widget_counts.query.graphql';
import {
  EVENT_FILTER_TODOS_ON_HOMEPAGE,
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_TODO_ITEMS,
  TRACKING_PROPERTY_ALL_TODOS,
} from '../tracking_constants';
import BaseWidget from './base_widget.vue';

const N_TODOS = 5;
const N_TODOS_FETCH = 15;
// Above this the badge reads "5+", so a long to-do list never widens the tab.
const N_BADGE_MAX = 5;

const FILTER_OPTIONS = [
  {
    countKey: null,
    value: null,
    text: s__('Todos|All'),
    trackingValue: 'everything',
  },
  {
    countKey: 'reviewRequested',
    value: TODO_ACTION_TYPE_REVIEW_REQUESTED,
    text: s__('Todos|Review requested'),
    trackingValue: TODO_ACTION_TYPE_REVIEW_REQUESTED,
  },
  {
    countKey: 'assigned',
    value: TODO_ACTION_TYPE_ASSIGNED,
    text: s__('Todos|Assigned'),
    trackingValue: TODO_ACTION_TYPE_ASSIGNED,
  },
  {
    countKey: 'buildFailed',
    value: TODO_ACTION_TYPE_BUILD_FAILED,
    text: s__('Todos|Build failed'),
    trackingValue: TODO_ACTION_TYPE_BUILD_FAILED,
  },
  {
    countKey: 'unmergeable',
    value: TODO_ACTION_TYPE_UNMERGEABLE,
    text: s__('Todos|Unmergeable'),
    trackingValue: TODO_ACTION_TYPE_UNMERGEABLE,
  },
  {
    countKey: 'reviewSubmitted',
    value: TODO_ACTION_TYPE_REVIEW_SUBMITTED,
    text: s__('Todos|Review submitted'),
    trackingValue: TODO_ACTION_TYPE_REVIEW_SUBMITTED,
  },
];

export default {
  name: 'TodosWidget',
  components: {
    TodoItem,
    GlBadge,
    GlTab,
    GlTabs,
    GlSkeletonLoader,
    BaseWidget,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  provide() {
    return {
      currentTime: new Date(),
      currentUserId: computed(() => this.currentUserId),
    };
  },
  data() {
    return {
      currentUserId: null,
      activeTabIndex: 0,
      counts: {},
      todos: [],
      showLoading: true,
      hasError: false,
    };
  },
  computed: {
    todoTrackingContext() {
      return { source: 'personal_homepage' };
    },
    activeOption() {
      return FILTER_OPTIONS[this.activeTabIndex];
    },
    filter() {
      return this.activeOption.value;
    },
    isFiltered() {
      return Boolean(this.filter);
    },
    displayedTodos() {
      return this.todos.slice(0, N_TODOS);
    },
    todosPath() {
      return dashboardTodosPath();
    },
  },
  apollo: {
    todos: {
      query: getTodosQuery,
      variables() {
        return {
          first: N_TODOS_FETCH,
          state: ['pending'],
          action: this.filter ? this.filter.split(';') : null,
        };
      },
      update({ currentUser }) {
        this.currentUserId = currentUser?.id;
        this.showLoading = false;

        return currentUser?.todos?.nodes ?? [];
      },
      error(error) {
        Sentry.captureException(error);
        this.showLoading = false;
        this.hasError = true;
      },
    },
    counts: {
      query: getTodosCountsQuery,
      variables() {
        return { limit: N_BADGE_MAX };
      },
      update({ currentUser } = {}) {
        return currentUser ?? {};
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  methods: {
    countFor(countKey) {
      return countKey ? this.counts[countKey]?.count : undefined;
    },
    hasCount(countKey) {
      return this.countFor(countKey) !== undefined;
    },
    // The limited count returns N_BADGE_MAX + 1 for anything above the cap, so
    // the exact total is unknown past that point.
    isCapped(countKey) {
      return this.countFor(countKey) > N_BADGE_MAX;
    },
    badgeText(countKey) {
      return this.isCapped(countKey) ? `${N_BADGE_MAX}+` : `${this.countFor(countKey)}`;
    },
    countSrText(countKey) {
      if (this.isCapped(countKey)) {
        return sprintf(s__('Todos|More than %{count} to-do items'), { count: N_BADGE_MAX });
      }

      return n__('%d to-do item', '%d to-do items', this.countFor(countKey));
    },
    reload() {
      this.showLoading = true;
      this.hasError = false;
      this.refetch();
    },
    refetch() {
      this.$apollo.queries.todos.refetch();
      this.$apollo.queries.counts.refetch();
    },
    handleTabChange(index) {
      if (index === this.activeTabIndex || index < 0) return;

      this.activeTabIndex = index;
      this.showLoading = true;

      this.trackEvent(EVENT_FILTER_TODOS_ON_HOMEPAGE, {
        property: this.activeOption.trackingValue,
      });
    },
    handleViewAllClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_TODO_ITEMS,
        property: TRACKING_PROPERTY_ALL_TODOS,
      });
    },
  },

  emptyTodosAllDoneSvg,
  emptyTodosFilteredSvg,
  FILTER_OPTIONS,
};
</script>

<template>
  <base-widget class="homepage-todos-widget" data-testid="homepage-todos-widget" @visible="reload">
    <h2 class="gl-heading-4 gl-mb-2">{{ __('Items that need your attention') }}</h2>

    <p v-if="hasError" class="gl-mb-0">
      {{
        s__(
          'HomePageTodosWidget|Your to-do items are not available. Please refresh the page to try again.',
        )
      }}
    </p>

    <template v-else>
      <gl-tabs
        :value="activeTabIndex"
        nav-class="gl-flex-nowrap"
        content-class="!gl-pb-0"
        @input="handleTabChange"
      >
        <gl-tab
          v-for="option in $options.FILTER_OPTIONS"
          :key="option.trackingValue"
          lazy
          title-item-class="gl-shrink-0"
          title-link-class="gl-whitespace-nowrap"
        >
          <template #title>
            <span>{{ option.text }}</span>
            <gl-badge
              v-if="hasCount(option.countKey)"
              class="gl-tab-counter-badge"
              variant="neutral"
              aria-hidden="true"
              data-testid="tab-count"
              >{{ badgeText(option.countKey) }}</gl-badge
            >
            <span v-if="hasCount(option.countKey)" class="gl-sr-only">{{
              countSrText(option.countKey)
            }}</span>
          </template>

          <div
            v-if="showLoading && $apollo.queries.todos.loading"
            class="gl-flex gl-flex-col gl-gap-y-4 gl-py-4"
          >
            <div v-for="i in 5" :key="i" class="gl-flex gl-items-center gl-justify-between">
              <gl-skeleton-loader :width="300" :lines="2" />
              <gl-skeleton-loader :width="50" :lines="1" :equal-width-lines="true" />
            </div>
          </div>

          <div
            v-else-if="!$apollo.queries.todos.loading && !todos.length && !isFiltered"
            class="gl-flex gl-items-center gl-gap-5 gl-rounded-lg gl-p-4"
          >
            <img class="gl-h-11" aria-hidden="true" :src="$options.emptyTodosAllDoneSvg" />
            <span>
              <strong>{{ __('Good job!') }}</strong>
              {{ __('All your to-do items are done.') }}
            </span>
          </div>

          <div
            v-else-if="!$apollo.queries.todos.loading && !todos.length && isFiltered"
            class="gl-flex gl-items-center gl-gap-5 gl-rounded-lg gl-p-4"
          >
            <img class="gl-h-11" aria-hidden="true" :src="$options.emptyTodosFilteredSvg" />
            <span>{{ __('Sorry, your filter produced no results') }}</span>
          </div>

          <ol v-else class="gl-m-0 gl-list-none gl-p-0">
            <todo-item
              v-for="todo in displayedTodos"
              :key="todo.id"
              class="-gl-mx-3 gl-rounded-lg gl-border-b-0 !gl-px-3 gl-py-4"
              :todo="todo"
              :tracking-additional="todoTrackingContext"
              @change="refetch"
            />
          </ol>
        </gl-tab>
      </gl-tabs>

      <div class="gl-pt-3">
        <a :href="todosPath" @click="handleViewAllClick">{{ __('All to-do items') }}</a>
      </div>
    </template>
  </base-widget>
</template>
