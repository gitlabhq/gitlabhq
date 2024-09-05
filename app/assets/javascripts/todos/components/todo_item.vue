<script>
import { GlLink } from '@gitlab/ui';
import { TODO_STATE_DONE, TODO_STATE_PENDING } from '../constants';
import TodoItemTitle from './todo_item_title.vue';
import TodoItemBody from './todo_item_body.vue';
import TodoItemTimestamp from './todo_item_timestamp.vue';
import TodoItemActions from './todo_item_actions.vue';

export default {
  components: {
    GlLink,
    TodoItemTitle,
    TodoItemBody,
    TodoItemTimestamp,
    TodoItemActions,
  },
  props: {
    currentUserId: {
      type: String,
      required: true,
    },
    todo: {
      type: Object,
      required: true,
    },
    fadeDoneTodo: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isDone() {
      return this.todo.state === TODO_STATE_DONE;
    },
    isPending() {
      return this.todo.state === TODO_STATE_PENDING;
    },
    targetUrl() {
      return this.todo.targetUrl;
    },
    fadeTodo() {
      return this.fadeDoneTodo && this.isDone;
    },
  },
};
</script>

<template>
  <li
    class="todo gl-border-t gl-border-b gl-relative -gl-mt-px gl-block gl-px-5 gl-py-3 hover:gl-z-1 hover:gl-cursor-pointer hover:gl-border-blue-200 hover:gl-bg-blue-50"
    :class="{
      'todo-pending': isPending,
      'todo-done gl-border-gray-50 gl-bg-gray-10': fadeTodo,
    }"
  >
    <gl-link
      :href="targetUrl"
      class="gl-flex gl-flex-wrap gl-gap-x-2 !gl-text-gray-900 !gl-no-underline !gl-outline-none sm:gl-flex-nowrap sm:gl-items-center"
    >
      <div
        class="gl-w-64 gl-flex-grow-2 gl-self-center gl-overflow-hidden gl-overflow-x-auto sm:gl-w-auto"
        :class="{ 'gl-opacity-5': fadeTodo }"
      >
        <todo-item-title :todo="todo" />
        <todo-item-body :todo="todo" :current-user-id="currentUserId" />
      </div>
      <todo-item-actions :todo="todo" class="sm:gl-order-3" />
      <todo-item-timestamp
        :todo="todo"
        class="gl-w-full gl-whitespace-nowrap gl-px-2 sm:gl-w-auto"
        :class="{ 'gl-opacity-5': fadeTodo }"
      />
    </gl-link>
  </li>
</template>
