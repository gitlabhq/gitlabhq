<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import {
  NEXT_CLEANUP_LABEL,
  NOT_SCHEDULED_POLICY_TEXT,
} from '~/packages_and_registries/settings/project/constants';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: NOT_SCHEDULED_POLICY_TEXT,
    },
    enabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    parsedValue() {
      return this.enabled ? this.value : NOT_SCHEDULED_POLICY_TEXT;
    },
  },
  i18n: {
    NEXT_CLEANUP_LABEL,
  },
};
</script>

<template>
  <gl-form-group
    id="expiration-policy-info-text-group"
    :label="$options.i18n.NEXT_CLEANUP_LABEL"
    label-for="expiration-policy-info-text"
  >
    <gl-form-input
      id="expiration-policy-info-text"
      class="gl-pl-0!"
      plaintext
      :value="parsedValue"
    />
  </gl-form-group>
</template>
