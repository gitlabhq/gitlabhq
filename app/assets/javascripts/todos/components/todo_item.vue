<script>
import { GlLink } from '@gitlab/ui';
import { INSTRUMENT_TODO_ITEM_FOLLOW, TODO_STATE_DONE } from '../constants';
import TodoItemTitle from './todo_item_title.vue';
import TodoItemBody from './todo_item_body.vue';
import TodoItemTimestamp from './todo_item_timestamp.vue';
import TodoItemActions from './todo_item_actions.vue';

export default {
  TRACK_ACTION: INSTRUMENT_TODO_ITEM_FOLLOW,
  components: {
    GlLink,
    TodoItemTitle,
    TodoItemBody,
    TodoItemTimestamp,
    TodoItemActions,
  },
  inject: ['currentTab'],
  props: {
    currentUserId: {
      type: String,
      required: true,
    },
    todo: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isDone() {
      return this.todo.state === TODO_STATE_DONE;
    },
    targetUrl() {
      return this.todo.targetUrl;
    },
    trackingLabel() {
      return this.todo.targetType ?? 'UNKNOWN';
    },
  },
};
</script>

<template>
  <li
    class="gl-border-t gl-border-b gl-relative -gl-mt-px gl-block gl-px-5 gl-py-3 hover:gl-z-1 hover:gl-cursor-pointer hover:gl-border-blue-200 hover:gl-bg-blue-50"
    :data-testid="`todo-item-${todo.id}`"
    :class="{ 'gl-bg-subtle': isDone }"
  >
    <gl-link
      :href="targetUrl"
      :data-track-label="trackingLabel"
      :data-track-action="$options.TRACK_ACTION"
      class="gl-flex gl-flex-wrap gl-justify-end gl-gap-x-2 !gl-text-default !gl-no-underline !gl-outline-none sm:gl-flex-nowrap sm:gl-items-center"
    >
      <div
        class="gl-w-64 gl-flex-grow-2 gl-self-center gl-overflow-hidden gl-overflow-x-auto sm:gl-w-auto"
      >
        <todo-item-title :todo="todo" />
        <todo-item-body :todo="todo" :current-user-id="currentUserId" />
      </div>
      <div class="sm:gl-order-3">
        <todo-item-actions
          :todo="todo"
          @change="(id, markedAsDone) => $emit('change', id, markedAsDone)"
        />
      </div>
      <todo-item-timestamp
        :todo="todo"
        class="gl-w-full gl-whitespace-nowrap gl-px-2 sm:gl-w-auto"
      />
    </gl-link>
  </li>
</template>
