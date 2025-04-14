<script>
import { GlLink, GlIcon, GlFormCheckbox } from '@gitlab/ui';
import { fallsBefore } from '~/lib/utils/datetime_utility';
import { INSTRUMENT_TODO_ITEM_FOLLOW, TODO_STATE_DONE } from '../constants';
import TodoItemTitle from './todo_item_title.vue';
import TodoItemBody from './todo_item_body.vue';
import TodoItemTimestamp from './todo_item_timestamp.vue';
import TodoSnoozedTimestamp from './todo_snoozed_timestamp.vue';
import TodoItemActions from './todo_item_actions.vue';
import TodoItemTitleHiddenBySaml from './todo_item_title_hidden_by_saml.vue';

export default {
  TRACK_ACTION: INSTRUMENT_TODO_ITEM_FOLLOW,
  components: {
    GlLink,
    GlIcon,
    GlFormCheckbox,
    TodoItemTitle,
    TodoItemBody,
    TodoItemTimestamp,
    TodoSnoozedTimestamp,
    TodoItemActions,
    TodoItemTitleHiddenBySaml,
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
    titleComponent() {
      return this.isHiddenBySaml ? TodoItemTitleHiddenBySaml : TodoItemTitle;
    },
    isDone() {
      return this.todo.state === TODO_STATE_DONE;
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
    class="gl-border-t gl-border-b gl-relative -gl-mt-px gl-flex gl-gap-3 gl-px-5 gl-py-3 hover:gl-bg-feedback-info"
    :data-testid="`todo-item-${todo.id}`"
    :class="{ 'gl-bg-subtle': isDone }"
  >
    <gl-form-checkbox
      class="gl-inline-block gl-pt-2"
      :aria-label="__('Select')"
      :checked="selected"
      @change="(checked) => $emit('select-change', todo.id, checked)"
    />
    <gl-link
      :href="targetUrl"
      :data-event-tracking="$options.TRACK_ACTION"
      :data-event-label="trackingLabel"
      :data-event-property="todo.action"
      class="gl-flex gl-min-w-0 gl-flex-1 gl-flex-wrap gl-justify-end gl-gap-y-3 !gl-text-default !gl-no-underline sm:gl-flex-nowrap sm:gl-items-center"
    >
      <div
        class="gl-w-64 gl-flex-grow-2 gl-self-center gl-overflow-hidden gl-overflow-x-auto sm:gl-w-auto"
      >
        <component
          :is="titleComponent"
          :todo="todo"
          class="gl-flex gl-items-center gl-gap-2 gl-overflow-hidden gl-whitespace-nowrap gl-px-2 gl-pb-3 gl-pt-2 gl-text-sm gl-text-subtle sm:gl-mr-0 sm:gl-pr-4 md:gl-mb-1"
        />
        <todo-item-body
          :todo="todo"
          :current-user-id="currentUserId"
          :is-hidden-by-saml="isHiddenBySaml"
        />
      </div>

      <todo-snoozed-timestamp
        v-if="todo.snoozedUntil"
        class="gl-mr-2"
        :snoozed-until="todo.snoozedUntil"
        :has-reached-snooze-timestamp="!isSnoozed"
      />

      <todo-item-timestamp
        :todo="todo"
        class="gl-w-full gl-whitespace-nowrap gl-px-2 sm:gl-w-auto"
      />
    </gl-link>
    <todo-item-actions
      class="gl-self-start sm:gl-self-center"
      :todo="todo"
      :is-snoozed="isSnoozed"
      @change="$emit('change')"
    />
  </li>
</template>
