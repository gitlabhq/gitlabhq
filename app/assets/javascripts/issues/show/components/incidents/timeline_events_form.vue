<script>
import {
  GlDatepicker,
  GlFormInput,
  GlFormGroup,
  GlButton,
  GlCollapsibleListbox,
  GlFormTextarea,
} from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, sprintf } from '~/locale';
import TimelineEventsTagsPopover from './timeline_events_tags_popover.vue';
import { MAX_TEXT_LENGTH, TIMELINE_EVENT_TAGS, timelineFormI18n } from './constants';
import { getUtcShiftedDate, getPreviousEventTags } from './utils';

export default {
  name: 'TimelineEventsForm',
  restrictedToolBarItems: [
    'quote',
    'strikethrough',
    'bullet-list',
    'numbered-list',
    'task-list',
    'collapsible-section',
    'table',
    'attach-file',
    'full-screen',
  ],
  components: {
    MarkdownField,
    TimelineEventsTagsPopover,
    GlDatepicker,
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlCollapsibleListbox,
    GlFormTextarea,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: timelineFormI18n,
  MAX_TEXT_LENGTH,
  props: {
    showSaveAndAdd: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEventProcessed: {
      type: Boolean,
      required: true,
    },
    previousOccurredAt: {
      type: String,
      required: false,
      default: null,
    },
    previousNote: {
      type: String,
      required: false,
      default: '',
    },
    previousTags: {
      type: Array,
      required: false,
      default: () => [],
    },
    tags: {
      type: Array,
      required: false,
      default: () => TIMELINE_EVENT_TAGS,
    },
  },
  data() {
    // if occurredAt is null, returns "now" in UTC
    const placeholderDate = getUtcShiftedDate(this.previousOccurredAt);

    return {
      timelineText: this.previousNote,
      timelineTextIsDirty: this.isEditing,
      placeholderDate,
      hourPickerInput: placeholderDate.getHours(),
      minutePickerInput: placeholderDate.getMinutes(),
      datePickerInput: placeholderDate,
      selectedTags: getPreviousEventTags(this.previousTags),
    };
  },
  computed: {
    isTimelineTextValid() {
      return this.timelineTextCount > 0 && this.timelineTextRemainingCount >= 0;
    },
    occurredAtString() {
      const year = this.datePickerInput.getFullYear();
      const month = this.datePickerInput.getMonth();
      const day = this.datePickerInput.getDate();

      const utcDate = new Date(
        Date.UTC(year, month, day, this.hourPickerInput, this.minutePickerInput),
      );

      return utcDate.toISOString();
    },
    timelineTextRemainingCount() {
      return MAX_TEXT_LENGTH - this.timelineTextCount;
    },
    timelineTextCount() {
      return this.timelineText.length;
    },
    listboxText() {
      if (!this.selectedTags.length) {
        return timelineFormI18n.selectTags;
      }

      const listboxText =
        this.selectedTags.length === 1
          ? this.selectedTags[0]
          : sprintf(__('%{numberOfSelectedTags} tags'), {
              numberOfSelectedTags: this.selectedTags.length,
            });

      return listboxText;
    },
  },
  mounted() {
    this.focusDate();
  },
  methods: {
    clear() {
      const newPlaceholderDate = getUtcShiftedDate();
      this.datePickerInput = newPlaceholderDate;
      this.hourPickerInput = newPlaceholderDate.getHours();
      this.minutePickerInput = newPlaceholderDate.getMinutes();
      this.timelineText = '';
      this.selectedTags = [];
    },
    focusDate() {
      this.$refs.datepicker.$el.querySelector('input')?.focus();
    },
    setTimelineTextDirty() {
      this.timelineTextIsDirty = true;
    },
    onTagsChange(tagValue) {
      this.selectedTags = [...tagValue];

      if (!this.timelineTextIsDirty) {
        this.timelineText = this.generateTimelineTextFromTags(this.selectedTags);
      }
    },
    generateTimelineTextFromTags(tags) {
      if (!tags.length) {
        return '';
      }

      const tagsMessage = tags.map((tag) => tag.toLocaleLowerCase()).join(', ');

      return `${timelineFormI18n.areaDefaultMessage} ${tagsMessage}`;
    },
    handleSave(addAnotherEvent) {
      const event = {
        note: this.timelineText,
        occurredAt: this.occurredAtString,
        timelineEventTags: this.selectedTags,
      };
      this.$emit('save-event', event, addAnotherEvent);
    },
  },
};
</script>

<template>
  <form class="gl-grow gl-border-subtle">
    <div class="gl-mt-3 gl-flex gl-flex-col sm:gl-flex-row">
      <gl-form-group :label="__('Date')" class="gl-mr-5">
        <gl-datepicker id="incident-date" ref="datepicker" v-model="datePickerInput" />
      </gl-form-group>
      <div class="gl-flex">
        <gl-form-group :label="__('Time')">
          <div class="gl-flex">
            <label label-for="timeline-input-hours" class="sr-only"></label>
            <gl-form-input
              id="timeline-input-hours"
              v-model="hourPickerInput"
              data-testid="input-hours"
              width="xs"
              type="number"
              min="00"
              max="23"
            />
            <label label-for="timeline-input-minutes" class="sr-only"></label>
            <gl-form-input
              id="timeline-input-minutes"
              v-model="minutePickerInput"
              class="gl-ml-3"
              data-testid="input-minutes"
              width="xs"
              type="number"
              min="00"
              max="59"
            />
          </div>
        </gl-form-group>
        <p class="gl-ml-3 gl-self-end gl-leading-32">{{ __('UTC') }}</p>
      </div>
    </div>
    <gl-form-group>
      <label class="gl-flex gl-items-center gl-gap-3" for="timeline-input-tags">
        {{ $options.i18n.tagsLabel }}
        <timeline-events-tags-popover />
      </label>
      <gl-collapsible-listbox
        id="timeline-input-tags"
        :selected="selectedTags"
        :toggle-text="listboxText"
        :items="tags"
        :is-check-centered="true"
        :multiple="true"
        @select="onTagsChange"
      />
    </gl-form-group>
    <div class="common-note-form">
      <gl-form-group class="gl-mb-3" :label="$options.i18n.areaLabel">
        <markdown-field
          :can-attach-file="false"
          :add-spacing-classes="false"
          :show-comment-tool-bar="false"
          :textarea-value="timelineText"
          :restricted-tool-bar-items="$options.restrictedToolBarItems"
          markdown-docs-path=""
          :enable-preview="false"
          class="gl-border gl-mt-0 gl-rounded-base gl-border-section"
        >
          <template #textarea>
            <gl-form-textarea
              v-model="timelineText"
              class="note-textarea-rounded-bottom js-gfm-input js-autosize markdown-area !gl-font-monospace"
              data-testid="input-note"
              dir="auto"
              no-resize
              data-supports-quick-actions="false"
              :aria-label="$options.i18n.description"
              aria-describedby="timeline-form-hint"
              :placeholder="$options.i18n.areaPlaceholder"
              :maxlength="$options.MAX_TEXT_LENGTH"
              @input="setTimelineTextDirty"
            />
            <div id="timeline-form-hint" class="gl-sr-only">{{ $options.i18n.hint }}</div>
            <div
              aria-hidden="true"
              class="gl-absolute gl-bottom-2 gl-right-4 gl-text-sm gl-text-subtle"
            >
              {{ timelineTextRemainingCount }}
            </div>
            <div role="status" class="gl-sr-only">
              {{ $options.i18n.textRemaining(timelineTextRemainingCount) }}
            </div>
          </template>
        </markdown-field>
      </gl-form-group>
    </div>
    <gl-form-group class="gl-mb-3">
      <div class="gl-flex gl-flex-wrap gl-gap-3">
        <gl-button
          variant="confirm"
          category="primary"
          data-testid="save-button"
          :disabled="!isTimelineTextValid"
          :loading="isEventProcessed"
          @click="handleSave(false)"
        >
          {{ $options.i18n.save }}
        </gl-button>
        <gl-button
          v-if="showSaveAndAdd"
          variant="confirm"
          category="secondary"
          data-testid="save-and-add-button"
          :disabled="!isTimelineTextValid"
          :loading="isEventProcessed"
          @click="handleSave(true)"
        >
          {{ $options.i18n.saveAndAdd }}
        </gl-button>
        <gl-button
          :disabled="isEventProcessed"
          data-testid="cancel-button"
          @click="$emit('cancel')"
        >
          {{ $options.i18n.cancel }}
        </gl-button>
        <gl-button
          v-if="isEditing"
          variant="danger"
          class="gl-ml-auto"
          data-testid="delete-button"
          :disabled="isEventProcessed"
          @click="$emit('delete')"
        >
          {{ $options.i18n.delete }}
        </gl-button>
      </div>
      <div class="timeline-event-bottom-border"></div>
    </gl-form-group>
  </form>
</template>
