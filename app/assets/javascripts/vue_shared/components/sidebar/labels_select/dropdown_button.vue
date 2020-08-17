<script>
import { GlIcon } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

export default {
  components: {
    GlIcon,
  },
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
    enableScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
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
    ref="dropdownButton"
    :class="{ 'js-extra-options': showExtraOptions }"
    :data-ability-name="abilityName"
    :data-field-name="fieldName"
    :data-issue-update="updatePath"
    :data-labels="labelsPath"
    :data-namespace-path="namespace"
    :data-show-any="showExtraOptions"
    :data-scoped-labels="enableScopedLabels"
    type="button"
    class="dropdown-menu-toggle wide js-label-select js-multiselect js-context-config-modal"
    data-toggle="dropdown"
  >
    <span class="dropdown-toggle-text"> {{ dropdownToggleText }} </span>
    <gl-icon
      name="chevron-down"
      class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500"
      :size="16"
    />
  </button>
</template>
