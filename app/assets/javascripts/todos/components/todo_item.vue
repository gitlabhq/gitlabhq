<script>
import { GlLink, GlFormCheckbox } from '@gitlab/ui';
import { fallsBefore } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';
import { INSTRUMENT_TODO_ITEM_FOLLOW, TODO_ACTION_TYPE_TRANSFER_FAILED } from '../constants';
import { getTransferFailedSource } from '../utils/transfer_failed_todo';
import TodoItemBody from './todo_item_body.vue';
import TodoItemTimestamp from './todo_item_timestamp.vue';
import TodoItemActions from './todo_item_actions.vue';

export default {
  name: 'TodoItem',
  TRACK_ACTION: INSTRUMENT_TODO_ITEM_FOLLOW,
  components: {
    GlLink,
    GlFormCheckbox,
    TodoItemBody,
    TodoItemTimestamp,
    TodoItemActions,
  },
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
    trackingAdditional: {
      type: Object,
      required: false,
      default: null,
    },
  },
  emits: ['change', 'select-change'],
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
    trackingAdditionalData() {
      return this.trackingAdditional ? JSON.stringify(this.trackingAdditional) : null;
    },
    isTransferFailedAction() {
      return this.todo.action === TODO_ACTION_TYPE_TRANSFER_FAILED;
    },
    transferFailedLinkLabel() {
      return sprintf(s__('Todos|View %{name}'), {
        name: getTransferFailedSource(this.todo),
      });
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
      class="gl-mt-[0.675rem] gl-inline-block"
      :aria-label="__('Select')"
      :checked="selected"
      @change="(checked) => $emit('select-change', todo.id, checked)"
    />
    <gl-link
      v-if="!isTransferFailedAction"
      :href="targetUrl"
      :data-event-tracking="$options.TRACK_ACTION"
      :data-event-label="trackingLabel"
      :data-event-property="todo.action"
      :data-event-additional="trackingAdditionalData"
      class="gl-flex gl-min-w-0 gl-grow gl-flex-col gl-flex-nowrap gl-justify-between gl-gap-3 gl-gap-y-3 gl-rounded-base !gl-text-default !gl-no-underline @sm/panel:gl-flex-row @sm/panel:gl-items-center"
    >
      <todo-item-body :todo="todo" :is-hidden-by-saml="isHiddenBySaml" />
      <todo-item-timestamp
        :todo="todo"
        :is-snoozed="isSnoozed"
        class="gl-mr-2 gl-mt-2 gl-self-start gl-whitespace-nowrap @sm/panel:gl-w-auto"
      />
    </gl-link>
    <div
      v-else
      class="gl-relative gl-flex gl-min-w-0 gl-grow gl-flex-col gl-flex-nowrap gl-justify-between gl-gap-3 gl-gap-y-3 gl-rounded-base @sm/panel:gl-flex-row @sm/panel:gl-items-center"
    >
      <gl-link
        :href="targetUrl"
        :aria-label="transferFailedLinkLabel"
        :data-event-tracking="$options.TRACK_ACTION"
        :data-event-label="trackingLabel"
        :data-event-property="todo.action"
        :data-event-additional="trackingAdditionalData"
        class="!gl-absolute gl-inset-0 !gl-z-1 gl-rounded-base"
        data-testid="todo-item-transfer-failed-link"
      />
      <todo-item-body :todo="todo" :is-hidden-by-saml="isHiddenBySaml" />
      <todo-item-timestamp
        :todo="todo"
        :is-snoozed="isSnoozed"
        class="gl-mr-2 gl-mt-2 gl-self-start gl-whitespace-nowrap @sm/panel:gl-w-auto"
      />
    </div>
    <todo-item-actions
      class="gl-mt-2 gl-self-start"
      :todo="todo"
      :is-snoozed="isSnoozed"
      @change="$emit('change')"
    />
  </li>
</template>
