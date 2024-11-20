<script>
import { GlButton, GlTooltipDirective, GlAnimatedTodoIcon } from '@gitlab/ui';
import { produce } from 'immer';
import { createAlert } from '~/alert';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Tracking from '~/tracking';
import { todoMutationTypes } from '../../constants';
import { todoQueries, todoMutations } from '../../queries/constants';
import { todoLabel } from '../../utils';
import TodoButton from './todo_button.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlButton,
    TodoButton,
    GlAnimatedTodoIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin(), trackingMixin],
  inject: {
    isClassicSidebar: {
      default: false,
    },
  },
  props: {
    issuableId: {
      type: String,
      required: true,
    },
    issuableIid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      todoId: null,
      loading: false,
    };
  },
  apollo: {
    todoId: {
      query() {
        return todoQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.issuableIid),
        };
      },
      skip() {
        return !this.issuableIid;
      },
      update(data) {
        return data.workspace?.issuable?.currentUserTodos.nodes[0]?.id;
      },
      result({ data }) {
        if (!data) {
          return;
        }

        const currentUserTodos = data.workspace?.issuable?.currentUserTodos?.nodes ?? [];
        this.todoId = currentUserTodos[0]?.id;
        this.$emit('todoUpdated', currentUserTodos.length > 0);
      },
      error() {
        createAlert({
          message: sprintf(__('Something went wrong while setting %{issuableType} to-do item.'), {
            issuableType: this.issuableType,
          }),
        });
      },
      subscribeToMore: {
        document() {
          return todoQueries[this.issuableType].subscription;
        },
        variables() {
          return {
            issuableId: this.issuableId,
          };
        },
        skip() {
          return !todoQueries[this.issuableType].subscription;
        },
      },
    },
  },
  computed: {
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
    todoIdQuery() {
      return todoQueries[this.issuableType].query;
    },
    todoIdQueryVariables() {
      return {
        fullPath: this.fullPath,
        iid: String(this.issuableIid),
      };
    },
    isLoading() {
      return this.$apollo.queries?.todoId?.loading || this.loading;
    },
    hasTodo() {
      return Boolean(this.todoId);
    },
    todoMutationType() {
      if (this.hasTodo) {
        return todoMutationTypes.markDone;
      }
      return todoMutationTypes.create;
    },
    tootltipTitle() {
      return todoLabel(this.hasTodo);
    },
    isNotificationsTodosButtons() {
      return this.glFeatures.notificationsTodosButtons;
    },
  },
  methods: {
    toggleTodo() {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: todoMutations[this.todoMutationType],
          variables: {
            input: {
              targetId: !this.hasTodo ? this.issuableId : undefined,
              id: this.hasTodo ? this.todoId : undefined,
            },
          },
          update: (
            store,
            {
              data: {
                todoMutation: { todo },
              },
            },
          ) => {
            const queryProps = {
              query: this.todoIdQuery,
              variables: this.todoIdQueryVariables,
            };
            const sourceData = store.readQuery(queryProps);
            const data = produce(sourceData, (draftState) => {
              draftState.workspace.issuable.currentUserTodos.nodes = this.hasTodo ? [] : [todo];
            });
            store.writeQuery({
              data,
              ...queryProps,
            });
          },
        })
        .then(
          ({
            data: {
              todoMutation: { errors },
            },
          }) => {
            if (errors.length) {
              createAlert({
                message: errors[0],
              });
            }
            this.track('click_todo', {
              label: 'right_sidebar',
              property: this.hasTodo,
            });
          },
        )
        .catch(() => {
          createAlert({
            message: sprintf(__('Something went wrong while setting %{issuableType} to-do item.'), {
              issuableType: this.issuableType,
            }),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <div data-testid="sidebar-todo" :class="{ 'inline-block': !isMergeRequest }">
    <todo-button
      v-if="isNotificationsTodosButtons"
      v-gl-tooltip.hover.top
      :title="tootltipTitle"
      :issuable-type="issuableType"
      :issuable-id="issuableId"
      :is-todo="hasTodo"
      :disabled="isLoading"
      :is-icon-button="true"
      class="hide-collapsed"
      @click.stop.prevent="toggleTodo"
    >
      <gl-animated-todo-icon :class="{ '!gl-text-blue-500': hasTodo }" :is-on="hasTodo" />
    </todo-button>
    <todo-button
      v-else
      :issuable-type="issuableType"
      :issuable-id="issuableId"
      :is-todo="hasTodo"
      :loading="isLoading"
      :size="isMergeRequest ? 'medium' : 'small'"
      class="hide-collapsed"
      @click.stop.prevent="toggleTodo"
    />
    <gl-button
      v-if="isClassicSidebar && !isMergeRequest"
      v-gl-tooltip.left.viewport
      :title="tootltipTitle"
      category="tertiary"
      type="reset"
      class="sidebar-collapsed-icon sidebar-collapsed-container !gl-rounded-none !gl-shadow-none"
      :class="{ '!gl-text-blue-500': hasTodo }"
      @click.stop.prevent="toggleTodo"
    >
      <gl-animated-todo-icon :is-on="hasTodo" />
    </gl-button>
  </div>
</template>
