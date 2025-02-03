<script>
import { GlLink, GlIcon, GlFormCheckbox } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import dateFormat from '~/lib/dateformat';
import { formatDate, getDayDifference, fallsBefore } from '~/lib/utils/datetime_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { INSTRUMENT_TODO_ITEM_FOLLOW, TODO_STATE_DONE } from '../constants';
import TodoItemTitle from './todo_item_title.vue';
import TodoItemBody from './todo_item_body.vue';
import TodoItemTimestamp from './todo_item_timestamp.vue';
import TodoItemActions from './todo_item_actions.vue';
import TodoItemTitleHiddenBySaml from './todo_item_title_hidden_by_saml.vue';

const ONE_WEEK = 6;
const TODAY = 0;
const TOMORROW = 1;

export default {
  TRACK_ACTION: INSTRUMENT_TODO_ITEM_FOLLOW,
  components: {
    GlLink,
    GlIcon,
    GlFormCheckbox,
    TodoItemTitle,
    TodoItemBody,
    TodoItemTimestamp,
    TodoItemActions,
    TodoItemTitleHiddenBySaml,
  },
  mixins: [timeagoMixin, glFeatureFlagMixin()],
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
      if (this.todo.snoozedUntil == null) {
        return false;
      }

      const snoozedUntil = new Date(this.todo.snoozedUntil);
      return !fallsBefore(snoozedUntil, new Date());
    },
    hasReachedSnoozeTimestamp() {
      return this.todo.snoozedUntil != null && !this.isSnoozed;
    },
    targetUrl() {
      return this.todo.targetUrl;
    },
    trackingLabel() {
      return this.todo.targetType ?? 'UNKNOWN';
    },
    formattedCreatedAt() {
      return sprintf(s__('Todos|First sent %{timeago}'), {
        timeago: this.timeFormatted(this.todo.createdAt),
      });
    },
    formattedSnoozedUntil() {
      if (!this.todo.snoozedUntil) {
        return null;
      }

      const snoozedUntil = new Date(this.todo.snoozedUntil);
      const difference = getDayDifference(new Date(), snoozedUntil);

      if (difference > ONE_WEEK) {
        return sprintf(s__('Todos|Snoozed until %{date}'), {
          date: formatDate(this.todo.snoozedUntil, 'mmm dd, yyyy'),
        });
      }

      const time = localeDateFormat.asTime.format(snoozedUntil);

      if (difference === TODAY) {
        return sprintf(s__('Todos|Snoozed until %{time}'), { time });
      }

      if (difference === TOMORROW) {
        return sprintf(s__('Todos|Snoozed until tomorrow, %{time}'), { time });
      }

      return sprintf(s__('Todos|Snoozed until %{day}, %{time}'), {
        day: dateFormat(snoozedUntil, 'DDDD'),
        time,
      });
    },
  },
};
</script>

<template>
  <li
    class="gl-border-t gl-border-b gl-relative -gl-mt-px gl-flex gl-gap-3 gl-px-5 gl-py-3 hover:gl-z-1 has-[>a:hover]:gl-border-blue-200 has-[>a:hover]:gl-bg-blue-50"
    :data-testid="`todo-item-${todo.id}`"
    :class="{ 'gl-bg-subtle': isDone }"
  >
    <gl-form-checkbox
      v-if="glFeatures.todosBulkActions"
      class="gl-inline-block gl-pt-2"
      :aria-label="__('Select')"
      :checked="selected"
      @change="(checked) => $emit('select-change', todo.id, checked)"
    />
    <gl-link
      :href="targetUrl"
      :data-track-label="trackingLabel"
      :data-track-action="$options.TRACK_ACTION"
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

      <span
        v-if="isSnoozed"
        class="gl-w-full gl-text-nowrap gl-px-2 gl-text-sm gl-text-subtle sm:gl-w-auto"
      >
        {{ formattedSnoozedUntil }}
      </span>
      <span
        v-else-if="hasReachedSnoozeTimestamp"
        class="gl-w-full gl-text-nowrap gl-px-2 gl-text-sm gl-text-subtle sm:gl-w-auto"
      >
        <gl-icon name="clock" class="gl-mr-2" />
        {{ formattedCreatedAt }}
      </span>
      <todo-item-timestamp
        v-else
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
