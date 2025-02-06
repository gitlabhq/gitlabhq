<script>
import { GlFormInput } from '@gitlab/ui';

import ImportTargetDropdown from '../../components/import_target_dropdown.vue';

import { validationMessageFor } from '../utils';
import { NEW_NAME_FIELD, TARGET_NAMESPACE_FIELD } from '../constants';

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
      return this.group.importTarget?.targetNamespace?.fullPath;
    },

    importTargetNewName() {
      return this.group.importTarget?.newName;
    },

    validationMessage() {
      return (
        this.group.progress?.message ||
        validationMessageFor(this.group.importTarget, TARGET_NAMESPACE_FIELD) ||
        validationMessageFor(this.group.importTarget, NEW_NAME_FIELD)
      );
    },

    validNameState() {
      // bootstrap-vue requires null for "indifferent" state, if we return true
      // this will highlight field in green like "passed validation"
      return this.group.flags.isInvalid && this.isPathSelectionAvailable ? false : null;
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
    <div class="gl-flex gl-items-stretch">
      <import-target-dropdown
        :selected="selectedImportTarget"
        :toggle-text="s__('BulkImport|Select parent group')"
        :disabled="!isPathSelectionAvailable"
        @select="onImportTargetSelect"
      />

      <div
        class="gl-flex gl-h-7 gl-items-center gl-border-0 gl-border-b-1 gl-border-t-1 gl-border-solid gl-bg-subtle gl-px-3"
        :class="{
          'gl-border-subtle gl-text-disabled': !isPathSelectionAvailable,
          'gl-border-strong': isPathSelectionAvailable,
        }"
      >
        /
      </div>
      <div class="gl-grow">
        <gl-form-input
          ref="newName"
          class="gl-rounded-bl-none gl-rounded-tl-none"
          :class="{
            '!gl-shadow-inner-1-border-strong': isPathSelectionAvailable,
            '!gl-shadow-inner-1-border-subtle': !isPathSelectionAvailable,
          }"
          debounce="500"
          data-testid="target-namespace-input"
          :disabled="!isPathSelectionAvailable"
          :value="importTargetNewName"
          :aria-label="__('New name')"
          :state="validNameState"
          @input="$emit('update-new-name', $event)"
        />
      </div>
    </div>
    <div
      v-if="isPathSelectionAvailable && (group.flags.isInvalid || validationMessage)"
      class="gl-m-0 gl-mt-2 gl-text-danger"
      role="alert"
    >
      {{ validationMessage }}
    </div>
  </div>
</template>
