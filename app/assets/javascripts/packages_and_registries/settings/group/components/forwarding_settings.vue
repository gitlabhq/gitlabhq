<script>
import { GlFormCheckbox, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { isEqual } from 'lodash';
import {
  PACKAGE_FORWARDING_CHECKBOX_LABEL,
  PACKAGE_FORWARDING_ENFORCE_LABEL,
} from '~/packages_and_registries/settings/group/constants';

export default {
  name: 'ForwardingSettings',
  i18n: {
    PACKAGE_FORWARDING_CHECKBOX_LABEL,
    PACKAGE_FORWARDING_ENFORCE_LABEL,
  },
  components: {
    GlFormCheckbox,
    GlFormGroup,
    GlSprintf,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    forwarding: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: true,
    },
    lockForwarding: {
      type: Boolean,
      required: false,
      default: false,
    },
    modelNames: {
      type: Object,
      required: true,
      validator(value) {
        return isEqual(Object.keys(value), ['forwarding', 'lockForwarding', 'isLocked']);
      },
    },
  },
  computed: {
    fields() {
      return [
        {
          testid: 'forwarding-checkbox',
          label: PACKAGE_FORWARDING_CHECKBOX_LABEL,
          updateField: this.modelNames.forwarding,
          checked: this.forwarding,
        },
        {
          testid: 'lock-forwarding-checkbox',
          label: PACKAGE_FORWARDING_ENFORCE_LABEL,
          updateField: this.modelNames.lockForwarding,
          checked: this.lockForwarding,
        },
      ];
    },
  },
  methods: {
    update(type, value) {
      this.$emit('update', type, value);
    },
  },
};
</script>

<template>
  <gl-form-group :label="label">
    <gl-form-checkbox
      v-for="field in fields"
      :key="field.testid"
      :checked="field.checked"
      :disabled="disabled"
      :data-testid="field.testid"
      @change="update(field.updateField, $event)"
    >
      <gl-sprintf :message="field.label">
        <template #packageType>
          {{ label }}
        </template>
      </gl-sprintf>
    </gl-form-checkbox>
  </gl-form-group>
</template>
