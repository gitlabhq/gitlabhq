<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import workItemCurrentUserTodosQuery from '../graphql/work_item_current_user_todos.query.graphql';
import workItemCurrentUserTodosUpdatedSubscription from '../graphql/work_item_current_user_todos.subscription.graphql';
import { updateWorkItemCurrentTodosWidget } from '../graphql/cache_utils';
import { findCurrentUserTodosWidget } from '../utils';
import TodosToggle from './shared/todos_toggle.vue';

export default {
  name: 'WorkItemTodosWidget',
  components: {
    TodosToggle,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['error'],
  data() {
    return {
      workItem: {},
    };
  },
  apollo: {
    workItem: {
      query: workItemCurrentUserTodosQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
          useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update(data) {
        return data?.namespace?.workItem ?? {};
      },
      error(error) {
        Sentry.captureException(error);
        this.$emit(
          'error',
          s__('WorkItem|Something went wrong when fetching the to-do state. Please try again.'),
        );
      },
      // `/todo` and `/done` change the to-do state server-side, so the widget listens for the
      // update rather than refetching: a refetch fans out across every query sharing the
      // `widgets` and `features` cache fields.
      subscribeToMore: {
        document: workItemCurrentUserTodosUpdatedSubscription,
        variables() {
          return {
            id: this.workItemId,
            useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
          };
        },
        skip() {
          return !this.workItemId;
        },
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    currentUserTodos() {
      return findCurrentUserTodosWidget(this.workItem)?.currentUserTodos?.nodes;
    },
  },
  methods: {
    updateCache({ cache, todos }) {
      updateWorkItemCurrentTodosWidget({
        cache,
        todos,
        fullPath: this.fullPath,
        iid: this.workItemIid,
      });
    },
  },
};
</script>

<template>
  <!-- TodosToggle reads its label once on creation, so wait for the to-do items to land -->
  <todos-toggle
    v-if="!isLoading"
    :item-id="workItemId"
    :current-user-todos="currentUserTodos"
    @todos-updated="updateCache"
    @error="$emit('error', $event)"
  />
</template>
