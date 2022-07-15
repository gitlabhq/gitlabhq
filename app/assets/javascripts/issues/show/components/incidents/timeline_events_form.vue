<script>
import { GlDatepicker, GlFormInput, GlFormGroup, GlButton, GlIcon } from '@gitlab/ui';
import { produce } from 'immer';
import { sortBy } from 'lodash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/graphql_shared/constants';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { createAlert } from '~/flash';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { sprintf } from '~/locale';
import { getUtcShiftedDateNow } from './utils';
import { timelineFormI18n } from './constants';

import CreateTimelineEvent from './graphql/queries/create_timeline_event.mutation.graphql';
import getTimelineEvents from './graphql/queries/get_timeline_events.query.graphql';

export default {
  name: 'IncidentTimelineEventForm',
  restrictedToolBarItems: [
    'quote',
    'strikethrough',
    'bullet-list',
    'numbered-list',
    'task-list',
    'collapsible-section',
    'table',
    'full-screen',
  ],
  components: {
    MarkdownField,
    GlDatepicker,
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlIcon,
  },
  i18n: timelineFormI18n,
  directives: {
    autofocusonshow,
  },
  inject: ['fullPath', 'issuableId'],
  props: {
    hasTimelineEvents: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    // Create shifted date to force the datepicker to format in UTC
    const utcShiftedDate = getUtcShiftedDateNow();
    return {
      currentDate: utcShiftedDate,
      currentHour: utcShiftedDate.getHours(),
      currentMinute: utcShiftedDate.getMinutes(),
      timelineText: '',
      createTimelineEventActive: false,
      datepickerTextInput: null,
    };
  },
  methods: {
    hideIncidentTimelineEventForm() {
      this.$emit('hide-incident-timeline-event-form');
    },
    focusDate() {
      this.$refs.datepicker.$el.focus();
    },
    updateCache(store, { data }) {
      const { timelineEvent: event, errors } = data?.timelineEventCreate || {};

      if (errors.length) {
        return;
      }

      const variables = {
        incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
        fullPath: this.fullPath,
      };

      const sourceData = store.readQuery({
        query: getTimelineEvents,
        variables,
      });

      const newData = produce(sourceData, (draftData) => {
        const { nodes: draftEventList } = draftData.project.incidentManagementTimelineEvents;
        draftEventList.push(event);
        // ISOStrings sort correctly in lexical order
        const sortedEvents = sortBy(draftEventList, 'occurredAt');
        draftData.project.incidentManagementTimelineEvents.nodes = sortedEvents;
      });

      store.writeQuery({
        query: getTimelineEvents,
        variables,
        data: newData,
      });
    },
    createIncidentTimelineEvent(addOneEvent) {
      this.createTimelineEventActive = true;
      return this.$apollo
        .mutate({
          mutation: CreateTimelineEvent,
          variables: {
            input: {
              incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
              note: this.timelineText,
              occurredAt: this.createDateString(),
            },
          },
          update: this.updateCache,
        })
        .then(({ data = {} }) => {
          const errors = data.timelineEventCreate?.errors;
          if (errors.length) {
            createAlert({
              message: sprintf(this.$options.i18n.createError, { error: errors.join('. ') }, false),
            });
          }
        })
        .catch((error) => {
          createAlert({
            message: this.$options.i18n.createErrorGeneric,
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.createTimelineEventActive = false;
          this.timelineText = '';
          if (addOneEvent) {
            this.hideIncidentTimelineEventForm();
          }
        });
    },
    createDateString() {
      const [years, months, days] = this.datepickerTextInput.split('-');
      const utcDate = new Date(
        Date.UTC(years, months - 1, days, this.currentHour, this.currentMinute),
      );
      return utcDate.toISOString();
    },
  },
};
</script>

<template>
  <div
    class="gl-relative gl-display-flex gl-align-items-center"
    :class="{ 'timeline-entry-vertical-line': hasTimelineEvents }"
  >
    <div
      v-if="hasTimelineEvents"
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-align-self-start gl-bg-white gl-text-gray-200 gl-border-gray-100 gl-border-1 gl-border-solid gl-rounded-full gl-mt-2 gl-mr-3 gl-w-8 gl-h-8 gl-z-index-1"
    >
      <gl-icon name="comment" class="note-icon" />
    </div>
    <form class="gl-flex-grow-1" :class="{ 'gl-border-t': hasTimelineEvents }">
      <div
        class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row datetime-picker"
      >
        <gl-form-group :label="__('Date')" class="gl-mt-3 gl-mr-3">
          <gl-datepicker id="incident-date" #default="{ formattedDate }" v-model="currentDate">
            <gl-form-input
              id="incident-date"
              ref="datepicker"
              v-model="datepickerTextInput"
              class="gl-datepicker-input gl-pr-7!"
              :value="formattedDate"
              :placeholder="__('YYYY-MM-DD')"
              @keydown.enter="onKeydown"
            />
          </gl-datepicker>
        </gl-form-group>
        <div class="gl-display-flex gl-mt-3">
          <gl-form-group :label="__('Time')">
            <div class="gl-display-flex">
              <label label-for="timeline-input-hours" class="sr-only"></label>
              <gl-form-input
                id="timeline-input-hours"
                v-model="currentHour"
                data-testid="input-hours"
                size="xs"
                type="number"
                min="00"
                max="23"
              />
              <label label-for="timeline-input-minutes" class="sr-only"></label>
              <gl-form-input
                id="timeline-input-minutes"
                v-model="currentMinute"
                class="gl-ml-3"
                data-testid="input-minutes"
                size="xs"
                type="number"
                min="00"
                max="59"
              />
            </div>
          </gl-form-group>
          <p class="gl-ml-3 gl-align-self-end gl-line-height-32">{{ __('UTC') }}</p>
        </div>
      </div>
      <div class="common-note-form">
        <gl-form-group :label="$options.i18n.areaLabel">
          <markdown-field
            :can-attach-file="false"
            :add-spacing-classes="false"
            :show-comment-tool-bar="false"
            :textarea-value="timelineText"
            :restricted-tool-bar-items="$options.restrictedToolBarItems"
            markdown-docs-path=""
            :enable-preview="false"
            class="bordered-box gl-mt-0"
          >
            <template #textarea>
              <textarea
                v-model="timelineText"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                dir="auto"
                data-supports-quick-actions="false"
                :aria-label="__('Description')"
                :placeholder="$options.i18n.areaPlaceholder"
              >
              </textarea>
            </template>
          </markdown-field>
        </gl-form-group>
      </div>
      <gl-form-group class="gl-mb-0">
        <gl-button
          variant="confirm"
          category="primary"
          class="gl-mr-3"
          :loading="createTimelineEventActive"
          @click="createIncidentTimelineEvent(true)"
        >
          {{ __('Save') }}
        </gl-button>
        <gl-button
          variant="confirm"
          category="secondary"
          class="gl-mr-3 gl-ml-n2"
          :loading="createTimelineEventActive"
          @click="createIncidentTimelineEvent(false)"
        >
          {{ $options.i18n.saveAndAdd }}
        </gl-button>
        <gl-button
          class="gl-ml-n2"
          :disabled="createTimelineEventActive"
          @click="hideIncidentTimelineEventForm"
        >
          {{ __('Cancel') }}
        </gl-button>
        <div class="gl-border-b gl-pt-5"></div>
      </gl-form-group>
    </form>
  </div>
</template>
