<script>
import { GlFormInput } from '@gitlab/ui';
import ImportTargetDropdown from '../../components/import_target_dropdown.vue';

import { getInvalidNameValidationMessage } from '../utils';

export default {
  components: {
    ImportTargetDropdown,
    GlFormInput,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },

  computed: {
    selectedImportTarget() {
      return this.group.importTarget.targetNamespace.fullPath || '';
    },
    validationMessage() {
      return (
        this.group.progress?.message || getInvalidNameValidationMessage(this.group.importTarget)
      );
    },
    validNameState() {
      // bootstrap-vue requires null for "indifferent" state, if we return true
      // this will highlight field in green like "passed validation"
      return this.group.flags.isInvalid && this.group.flags.isAvailableForImport ? false : null;
    },
    isPathSelectionAvailable() {
      return this.group.flags.isAvailableForImport;
    },
  },

  methods: {
    focusNewName() {
      this.$refs.newName.$el.focus();
    },

    onImportTargetSelect(namespace) {
      this.$emit('update-target-namespace', namespace);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-align-items-stretch">
      <import-target-dropdown
        :selected="selectedImportTarget"
        :disabled="!isPathSelectionAvailable"
        @select="onImportTargetSelect"
      />

      <div
        class="gl-h-7 gl-px-3 gl-display-flex gl-align-items-center gl-border-solid gl-border-0 gl-border-t-1 gl-border-b-1 gl-bg-gray-10"
        :class="{
          'gl-text-gray-400 gl-border-gray-100': !isPathSelectionAvailable,
          'gl-border-gray-200': isPathSelectionAvailable,
        }"
      >
        /
      </div>
      <div class="gl-flex-grow-1">
        <gl-form-input
          ref="newName"
          class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
          :class="{
            'gl-inset-border-1-gray-200!': isPathSelectionAvailable,
            'gl-inset-border-1-gray-100!': !isPathSelectionAvailable,
          }"
          debounce="500"
          data-testid="target-namespace-input"
          :disabled="!isPathSelectionAvailable"
          :value="group.importTarget.newName"
          :aria-label="__('New name')"
          :state="validNameState"
          @input="$emit('update-new-name', $event)"
        />
      </div>
    </div>
    <div
      v-if="isPathSelectionAvailable && (group.flags.isInvalid || validationMessage)"
      class="gl-text-red-500 gl-m-0 gl-mt-2"
      role="alert"
    >
      {{ validationMessage }}
    </div>
  </div>
</template>
