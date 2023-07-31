<script>
import { GlDatepicker, GlFilteredSearchToken } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlDatepicker,
    GlFilteredSearchToken,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedDate: null,
    };
  },
  methods: {
    selectValue(value) {
      this.selectedDate = formatDate(value, 'yyyy-mm-dd');
    },
    close(submitValue) {
      if (this.selectedDate == null) {
        return;
      }

      submitValue(this.selectedDate);
    },
    handle() {
      const listeners = { ...this.$listeners };
      // If we don't remove this, clicking the month/year in the datepicker will deactivate
      delete listeners.deactivate;
      return listeners;
    },
  },
  dataSegmentInputAttributes: {
    id: 'glfs-datepicker',
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
        class="gl-display-none!"
        target="#glfs-datepicker"
        :container="null"
        @input="selectValue($event)"
        @close="close(submitValue)"
      />
    </template>
  </gl-filtered-search-token>
</template>
