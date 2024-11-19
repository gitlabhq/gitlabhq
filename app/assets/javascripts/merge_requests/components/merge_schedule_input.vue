<script>
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';

const ANYTIME = 'anytime';
const AFTER = 'after';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormInput,
  },
  props: {
    mergeAfter: {
      type: String,
      required: false,
      default: undefined,
    },
    paramKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedMode: this.mergeAfter !== undefined ? AFTER : ANYTIME,
      localMergeAfter: formatDate(this.mergeAfter, "yyyy-mm-dd'T'HH:MM"),
    };
  },
  computed: {
    actualMergeAfter() {
      if (this.selectedMode === ANYTIME) {
        return '';
      }

      return new Date(this.localMergeAfter).toJSON();
    },
    dropdownValues() {
      return [
        {
          text: __('Anytime'),
          value: ANYTIME,
        },
        {
          text: __('After scheduled date'),
          value: AFTER,
        },
      ];
    },
    shouldDisplayAfterInput() {
      return this.selectedMode === AFTER;
    },
  },
};
</script>

<template>
  <div class="col-12">
    <gl-collapsible-listbox v-model="selectedMode" :items="dropdownValues" />
    <div class="issuable-form-select-holder">
      <gl-form-input
        v-if="shouldDisplayAfterInput"
        v-model="localMergeAfter"
        type="datetime-local"
      />
    </div>
    <input type="hidden" :name="`${paramKey}[merge_after]`" :value="actualMergeAfter" />
  </div>
</template>
