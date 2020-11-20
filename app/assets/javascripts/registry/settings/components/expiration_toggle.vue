<script>
import { GlFormGroup, GlToggle, GlSprintf } from '@gitlab/ui';
import { ENABLED_TEXT, DISABLED_TEXT, ENABLE_TOGGLE_DESCRIPTION } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlToggle,
    GlSprintf,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    ENABLE_TOGGLE_DESCRIPTION,
  },
  computed: {
    enabled: {
      get() {
        return this.value;
      },
      set(value) {
        this.$emit('input', value);
      },
    },
    toggleStatusText() {
      return this.enabled ? ENABLED_TEXT : DISABLED_TEXT;
    },
  },
};
</script>

<template>
  <gl-form-group id="expiration-policy-toggle-group" label-for="expiration-policy-toggle">
    <div class="gl-display-flex">
      <gl-toggle id="expiration-policy-toggle" v-model="enabled" :disabled="disabled" />
      <span class="gl-ml-5 gl-line-height-24" data-testid="description">
        <gl-sprintf :message="$options.i18n.ENABLE_TOGGLE_DESCRIPTION">
          <template #toggleStatus>
            <strong>{{ toggleStatusText }}</strong>
          </template>
        </gl-sprintf>
      </span>
    </div>
  </gl-form-group>
</template>
