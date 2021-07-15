<script>
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import TodoButton from '~/vue_shared/components/sidebar/todo_toggle/todo_button.vue';
import createDesignTodoMutation from '../graphql/mutations/create_design_todo.mutation.graphql';
import getDesignQuery from '../graphql/queries/get_design.query.graphql';
import allVersionsMixin from '../mixins/all_versions';
import { updateStoreAfterDeleteDesignTodo } from '../utils/cache_update';
import { findIssueId, findDesignId } from '../utils/design_management_utils';
import { CREATE_DESIGN_TODO_ERROR, DELETE_DESIGN_TODO_ERROR } from '../utils/error_messages';

export default {
  components: {
    TodoButton,
  },
  mixins: [allVersionsMixin],
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
  },
  props: {
    design: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      todoLoading: false,
    };
  },
  computed: {
    designVariables() {
      return {
        fullPath: this.projectPath,
        iid: this.issueIid,
        filenames: [this.$route.params.id],
        atVersion: this.designsVersion,
      };
    },
    designTodoVariables() {
      return {
        projectPath: this.projectPath,
        issueId: findIssueId(this.design.issue.id),
        designId: findDesignId(this.design.id),
        issueIid: this.issueIid,
        filenames: [this.$route.params.id],
        atVersion: this.designsVersion,
      };
    },
    pendingTodo() {
      // TODO data structure pending BE MR: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40555#note_405732940
      return this.design.currentUserTodos?.nodes[0];
    },
    hasPendingTodo() {
      return Boolean(this.pendingTodo);
    },
  },
  methods: {
    createTodo() {
      this.todoLoading = true;
      return this.$apollo
        .mutate({
          mutation: createDesignTodoMutation,
          variables: this.designTodoVariables,
          update: (store, { data: { createDesignTodo } }) => {
            // because this is a @client mutation,
            // we control what is in errors, and therefore
            // we are certain that there is at most 1 item in the array
            const createDesignTodoError = (createDesignTodo.errors || [])[0];
            if (createDesignTodoError) {
              this.$emit('error', Error(createDesignTodoError.message));
            }
          },
        })
        .catch((err) => {
          this.$emit('error', Error(CREATE_DESIGN_TODO_ERROR));
          throw err;
        })
        .finally(() => {
          this.todoLoading = false;
        });
    },
    deleteTodo() {
      if (!this.hasPendingTodo) return Promise.reject();

      const { id } = this.pendingTodo;
      const { designVariables } = this;

      this.todoLoading = true;
      return this.$apollo
        .mutate({
          mutation: todoMarkDoneMutation,
          variables: {
            id,
          },
          update(store, { data: { todoMarkDone } }) {
            const todoMarkDoneFirstError = (todoMarkDone.errors || [])[0];
            if (todoMarkDoneFirstError) {
              this.$emit('error', Error(todoMarkDoneFirstError));
            } else {
              updateStoreAfterDeleteDesignTodo(
                store,
                todoMarkDone,
                getDesignQuery,
                designVariables,
              );
            }
          },
        })
        .catch((err) => {
          this.$emit('error', Error(DELETE_DESIGN_TODO_ERROR));
          throw err;
        })
        .finally(() => {
          this.todoLoading = false;
        });
    },
    toggleTodo() {
      if (this.hasPendingTodo) {
        return this.deleteTodo();
      }

      return this.createTodo();
    },
  },
};
</script>

<template>
  <todo-button
    issuable-type="design"
    :issuable-id="design.iid"
    :is-todo="hasPendingTodo"
    :loading="todoLoading"
    @click.stop.prevent="toggleTodo"
  />
</template>
