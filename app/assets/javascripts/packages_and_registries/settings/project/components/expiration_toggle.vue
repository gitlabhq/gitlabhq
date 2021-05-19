<script>
import { GlFormGroup, GlToggle, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  ENABLED_TOGGLE_DESCRIPTION,
  DISABLED_TOGGLE_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';

export default {
  i18n: {
    toggleLabel: s__('ContainerRegistry|Enable expiration policy'),
  },
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
  computed: {
    enabled: {
      get() {
        return this.value;
      },
      set(value) {
        this.$emit('input', value);
      },
    },
    toggleText() {
      return this.enabled ? ENABLED_TOGGLE_DESCRIPTION : DISABLED_TOGGLE_DESCRIPTION;
    },
  },
};
</script>

<template>
  <gl-form-group id="expiration-policy-toggle-group" label-for="expiration-policy-toggle">
    <div class="gl-display-flex">
      <gl-toggle
        id="expiration-policy-toggle"
        v-model="enabled"
        :label="$options.i18n.toggleLabel"
        label-position="hidden"
        :disabled="disabled"
      />
      <span class="gl-ml-5 gl-line-height-24" data-testid="description">
        <gl-sprintf :message="toggleText">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </span>
    </div>
  </gl-form-group>
</template>
