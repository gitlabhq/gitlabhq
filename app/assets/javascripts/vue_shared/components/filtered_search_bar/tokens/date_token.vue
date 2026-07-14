<script>
import { GlDatepicker, GlFilteredSearchToken } from '@gitlab/ui';
import { toISODateFormat } from '~/lib/utils/datetime_utility';
import { BACKSPACE_KEY, TAB_KEY, ENTER_KEY } from '~/lib/utils/keys';

const DATEPICKER_INPUT_ID = 'glfs-datepicker';
const SEGMENT_INPUT_CLASS = 'gl-filtered-search-token-segment-input';

export default {
  name: 'DateToken',
  components: {
    GlDatepicker,
    GlFilteredSearchToken,
  },
  props: {
    active: { type: Boolean, required: true },
    config: { type: Object, required: true },
    value: { type: Object, required: true },
  },
  data() {
    return {
      selectedDate: null,
      inputCleared: false,
    };
  },
  mounted() {
    // The data segment of gl-filtered-search-token does not forward keydown to
    // the slot, so we listen on this token's own root element (capture phase)
    // rather than document, to avoid intercepting keystrokes page-wide.
    this.$el.addEventListener('keydown', this.handleKeydownCapture, true);
  },
  beforeDestroy() {
    this.$el.removeEventListener('keydown', this.handleKeydownCapture, true);
  },
  methods: {
    handleKeydownCapture(e) {
      const onDatepickerInput = e.target.id === DATEPICKER_INPUT_ID;
      const onSegmentInput = e.target.classList?.contains(SEGMENT_INPUT_CLASS);

      if (e.key === TAB_KEY && (onDatepickerInput || onSegmentInput)) {
        e.preventDefault();
        e.stopPropagation();
      }
      if (e.key === BACKSPACE_KEY && onDatepickerInput) {
        this.clearDate();
      }
    },
    selectValue(value) {
      if (this.inputCleared) {
        return;
      }
      this.selectedDate = toISODateFormat(value);
    },
    close(submitValue) {
      if (this.inputCleared) {
        this.selectedDate = null;
        return;
      }
      if (this.selectedDate == null) {
        return;
      }
      submitValue(this.selectedDate);
    },
    handleDatepickerKeydown(event, submitValue) {
      if (event.key === TAB_KEY || event.key === ENTER_KEY) {
        if (this.selectedDate !== null) {
          submitValue(this.selectedDate);
          this.selectedDate = null;
        }
      }
      if (event.key === BACKSPACE_KEY && event.target?.value === '') {
        this.clearDate();
      }
    },
    clearDate() {
      this.inputCleared = true;
      this.selectedDate = null;
    },
    onDatepickerClose(submitValue) {
      this.$el.querySelector(`#${DATEPICKER_INPUT_ID}`)?.focus();
      this.close(submitValue);
    },
    handle() {
      const listeners = { ...this.$listeners };
      // If we don't remove this, clicking the month/year in the datepicker will deactivate
      delete listeners.deactivate;
      return listeners;
    },
  },
  dataSegmentInputAttributes: {
    id: DATEPICKER_INPUT_ID,
    placeholder: 'YYYY-MM-DD',
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    :value="value"
    :active="active"
    :data-segment-input-attributes="$options.dataSegmentInputAttributes"
    v-bind="{ ...$props, ...$attrs }"
    v-on="handle()"
  >
    <template #before-data-segment-input="{ submitValue }">
      <gl-datepicker
        class="!gl-hidden"
        target="#glfs-datepicker"
        :container="null"
        @input="selectValue($event)"
        @open="inputCleared = false"
        @close="onDatepickerClose(submitValue)"
        @keydown="handleDatepickerKeydown($event, submitValue)"
      />
    </template>
  </gl-filtered-search-token>
</template>
