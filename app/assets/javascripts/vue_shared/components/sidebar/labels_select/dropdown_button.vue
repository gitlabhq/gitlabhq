<script>
import { __, s__, sprintf } from '~/locale';

export default {
  props: {
    abilityName: {
      type: String,
      required: true,
    },
    fieldName: {
      type: String,
      required: true,
    },
    updatePath: {
      type: String,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: true,
    },
    labels: {
      type: Array,
      required: true,
    },
    showExtraOptions: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    dropdownToggleText() {
      if (this.labels.length === 0) {
        return __('Label');
      }

      if (this.labels.length > 1) {
        return sprintf(s__('LabelSelect|%{firstLabelName} +%{remainingLabelCount} more'), {
          firstLabelName: this.labels[0].title,
          remainingLabelCount: this.labels.length - 1,
        });
      }

      return this.labels[0].title;
    },
  },
};
</script>

<template>
  <button
    type="button"
    ref="dropdownButton"
    class="dropdown-menu-toggle wide js-label-select js-multiselect js-context-config-modal"
    data-toggle="dropdown"
    :class="{ 'js-extra-options': showExtraOptions }"
    :data-ability-name="abilityName"
    :data-field-name="fieldName"
    :data-issue-update="updatePath"
    :data-labels="labelsPath"
    :data-namespace-path="namespace"
    :data-show-any="showExtraOptions"
  >
    <span class="dropdown-toggle-text">
      {{ dropdownToggleText }}
    </span>
    <i
      aria-hidden="true"
      class="fa fa-chevron-down"
      data-hidden="true"
    >
    </i>
  </button>
</template>
