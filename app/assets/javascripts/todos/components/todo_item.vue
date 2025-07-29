<script>
import { GlLink, GlFormCheckbox } from '@gitlab/ui';
import { fallsBefore } from '~/lib/utils/datetime_utility';
import { INSTRUMENT_TODO_ITEM_FOLLOW } from '../constants';
import TodoItemBody from './todo_item_body.vue';
import TodoItemTimestamp from './todo_item_timestamp.vue';
import TodoItemActions from './todo_item_actions.vue';

export default {
  TRACK_ACTION: INSTRUMENT_TODO_ITEM_FOLLOW,
  components: {
    GlLink,
    GlFormCheckbox,
    TodoItemBody,
    TodoItemTimestamp,
    TodoItemActions,
  },
  inject: ['currentTab'],
  props: {
    todo: {
      type: Object,
      required: true,
    },
    selectable: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isHiddenBySaml() {
      return !this.todo.targetEntity;
    },
    isSnoozed() {
      if (this.todo.snoozedUntil === null) {
        return false;
      }

      const snoozedUntil = new Date(this.todo.snoozedUntil);
      return !fallsBefore(snoozedUntil, new Date());
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
    class="gl-border-b gl-flex gl-gap-3 gl-px-5 gl-py-3 hover:gl-bg-subtle"
    :data-testid="`todo-item-${todo.id}`"
  >
    <gl-form-checkbox
      v-if="selectable"
      class="gl-mt-1 gl-inline-block"
      :aria-label="__('Select')"
      :checked="selected"
      @change="(checked) => $emit('select-change', todo.id, checked)"
    />
    <gl-link
      :href="targetUrl"
      :data-event-tracking="$options.TRACK_ACTION"
      :data-event-label="trackingLabel"
      :data-event-property="todo.action"
      class="gl-flex gl-min-w-0 gl-grow gl-flex-col gl-flex-nowrap gl-justify-between gl-gap-3 gl-gap-y-3 !gl-text-default !gl-no-underline sm:gl-flex-row sm:gl-items-center"
    >
      <todo-item-body :todo="todo" :is-hidden-by-saml="isHiddenBySaml" />
      <todo-item-timestamp
        :todo="todo"
        :is-snoozed="isSnoozed"
        class="gl-self-start gl-whitespace-nowrap sm:gl-w-auto"
      />
    </gl-link>
    <todo-item-actions
      class="gl-self-start"
      :todo="todo"
      :is-snoozed="isSnoozed"
      @change="$emit('change')"
    />
  </li>
</template>
