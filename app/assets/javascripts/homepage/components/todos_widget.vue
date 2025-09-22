<script>
import { computed } from 'vue';
import { GlCollapsibleListbox, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import emptyTodosAllDoneSvg from '@gitlab/svgs/dist/illustrations/status/status-success-sm.svg';
import emptyTodosFilteredSvg from '@gitlab/svgs/dist/illustrations/search-sm.svg';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
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
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_TODO_ITEMS,
  TRACKING_PROPERTY_ALL_TODOS,
} from '../tracking_constants';
import BaseWidget from './base_widget.vue';

const N_TODOS = 5;
const N_TODOS_FETCH = 15;

const FILTER_OPTIONS = [
  {
    value: null,
    text: s__('Todos|Everything'),
    description: s__('Todos|All your pending to-do items across GitLab.'),
  },
  {
    value: TODO_ACTION_TYPE_ASSIGNED,
    text: s__('Todos|Assignments'),
    description: s__('Todos|Items assigned to you.'),
  },
  {
    value: `${TODO_ACTION_TYPE_MENTIONED};${TODO_ACTION_TYPE_DIRECTLY_ADDRESSED}`,
    text: s__('Todos|Mentions'),
    description: s__('Todos|Items where you were mentioned (@username).'),
  },
  {
    value: TODO_ACTION_TYPE_BUILD_FAILED,
    text: s__('Todos|Failed builds'),
    description: s__('Todos|Merge requests with failed pipelines.'),
  },
  {
    value: TODO_ACTION_TYPE_UNMERGEABLE,
    text: s__('Todos|Unmergeable changes'),
    description: s__(
      'Todos|Merge requests that cannot be merged due to conflicts or other issues.',
    ),
  },
  {
    value: TODO_ACTION_TYPE_REVIEW_REQUESTED,
    text: s__('Todos|Requested reviews'),
    description: s__('Todos|Merge requests that require your review or approval.'),
  },
];

export default {
  components: {
    TodoItem,
    GlCollapsibleListbox,
    GlSkeletonLoader,
    BaseWidget,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
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
      showLoading: true,
      hasError: false,
    };
  },
  computed: {
    todoTrackingContext() {
      return { source: 'personal_homepage' };
    },
    selectedFilterText() {
      const selectedOption = FILTER_OPTIONS.find((option) => option.value === this.filter);
      return selectedOption ? selectedOption.text : s__('Todos|All');
    },
    displayedTodos() {
      return this.todos.slice(0, N_TODOS);
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
      update({ currentUser: { id, todos: { nodes = [] } } = {} }) {
        this.currentUserId = id;
        this.showLoading = false;

        return nodes;
      },
      error(error) {
        Sentry.captureException(error);
        this.showLoading = false;
        this.hasError = true;
      },
    },
  },
  methods: {
    reload() {
      this.showLoading = true;
      this.hasError = false;
      this.$apollo.queries.todos.refetch();
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
  <base-widget @visible="reload">
    <div class="gl-mb-2 gl-flex gl-items-center gl-justify-between gl-gap-2">
      <div class="gl-flex gl-items-center gl-gap-2">
        <h2 class="gl-heading-4 gl-m-0 gl-grow">{{ __('Items that need your attention') }}</h2>
      </div>

      <gl-collapsible-listbox
        v-if="!hasError"
        v-model="filter"
        :items="$options.FILTER_OPTIONS"
        :toggle-text="selectedFilterText"
      >
        <template #list-item="{ item }">
          <div class="gl-flex gl-w-full gl-flex-col gl-gap-1">
            <div class="gl-font-weight-semibold gl-text-default">{{ item.text }}</div>
            <div class="gl-line-height-normal gl-text-sm gl-text-subtle">
              {{ item.description }}
            </div>
          </div>
        </template>
      </gl-collapsible-listbox>
    </div>

    <p v-if="hasError" class="gl-mb-3">
      {{
        s__(
          'HomePageTodosWidget|Your to-do items are not available. Please refresh the page to try again.',
        )
      }}
    </p>
    <template v-else>
      <div v-if="showLoading && $apollo.queries.todos.loading" class="gl-p-4">
        <gl-skeleton-loader v-for="i in 5" :key="i" :width="200" :height="10">
          <rect x="0" y="0" width="16" height="8" rx="2" ry="2" />
          <rect x="24" y="0" width="174" height="8" rx="2" ry="2" />
          <rect x="182" y="0" width="16" height="8" rx="2" ry="2" />
        </gl-skeleton-loader>
      </div>

      <div
        v-else-if="!$apollo.queries.todos.loading && !todos.length && !filter"
        class="gl-flex gl-items-center gl-gap-5 gl-rounded-lg gl-p-4"
      >
        <img class="gl-h-11" aria-hidden="true" :src="$options.emptyTodosAllDoneSvg" />
        <span>
          <strong>{{ __('Good job!') }}</strong>
          {{ __('All your to-do items are done.') }}
        </span>
      </div>
      <div
        v-else-if="!$apollo.queries.todos.loading && !todos.length && filter"
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
          @change="$apollo.queries.todos.refetch()"
        />
      </ol>

      <div class="gl-pt-3">
        <a href="/dashboard/todos" @click="handleViewAllClick">{{ __('All to-do items') }}</a>
      </div>
    </template>
  </base-widget>
</template>
