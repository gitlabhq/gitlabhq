<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { updateGlobalTodoCount } from '~/sidebar/utils';
import workItemCurrentUserTodosQuery from '../graphql/work_item_current_user_todos.query.graphql';
import workItemCurrentUserTodosUpdatedSubscription from '../graphql/work_item_current_user_todos.subscription.graphql';
import updateWorkItemCurrentUserTodosMutation from '../graphql/update_work_item_current_user_todos.mutation.graphql';
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
      isUpdating: false,
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
      return findCurrentUserTodosWidget(this.workItem)?.currentUserTodos?.nodes ?? [];
    },
  },
  methods: {
    onToggle() {
      // The mutation result empties `currentUserTodos`, so the count has to be read up front.
      const todoCount = this.currentUserTodos.length;
      const isMarkingDone = todoCount > 0;
      this.isUpdating = true;

      this.$apollo
        .mutate({
          mutation: updateWorkItemCurrentUserTodosMutation,
          variables: {
            input: {
              id: this.workItemId,
              currentUserTodosWidget: { action: isMarkingDone ? 'MARK_AS_DONE' : 'ADD' },
            },
            useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
          },
        })
        .then(({ data }) => {
          const { errors } = data.workItemUpdate;

          if (errors?.length) {
            throw new Error(errors[0]);
          }

          updateGlobalTodoCount(isMarkingDone ? -todoCount : 1);
        })
        .catch((error) => {
          this.$emit('error', error.message);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<template>
  <!-- Rendering before the to-do items land would offer "Add" on an item that already has one -->
  <todos-toggle
    v-if="!isLoading"
    :current-user-todos="currentUserTodos"
    :is-updating="isUpdating"
    @toggle="onToggle"
  />
</template>
