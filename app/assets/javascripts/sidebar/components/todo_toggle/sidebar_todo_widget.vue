<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { produce } from 'immer';
import { createAlert } from '~/alert';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Tracking from '~/tracking';
import { todoQueries, TodoMutationTypes, todoMutations } from '../../constants';
import { todoLabel } from '../../utils';
import TodoButton from './todo_button.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlButton,
    GlIcon,
    TodoButton,
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
    },
  },
  computed: {
    isMergeRequest() {
      return this.glFeatures.movedMrSidebar && this.issuableType === TYPE_MERGE_REQUEST;
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
        return TodoMutationTypes.MarkDone;
      }
      return TodoMutationTypes.Create;
    },
    collapsedButtonIcon() {
      return this.hasTodo ? 'todo-done' : 'todo-add';
    },
    tootltipTitle() {
      return todoLabel(this.hasTodo);
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
  <div data-testid="sidebar-todo">
    <todo-button
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
      class="sidebar-collapsed-icon sidebar-collapsed-container gl-rounded-0! gl-shadow-none!"
      @click.stop.prevent="toggleTodo"
    >
      <gl-icon :class="{ 'todo-undone': hasTodo }" :name="collapsedButtonIcon" />
    </gl-button>
  </div>
</template>
