<script>
import { GlToggle } from '@gitlab/ui';
import {
  I18N_SHOW_ONLY_INHERITED,
  MEMBERSHIP_DESCENDANTS,
  MEMBERSHIP_ALL_AVAILABLE,
} from '../constants';

export default {
  components: {
    GlToggle,
  },
  props: {
    value: {
      type: String,
      default: MEMBERSHIP_DESCENDANTS,
      required: false,
    },
  },
  computed: {
    toggle() {
      return this.value === MEMBERSHIP_DESCENDANTS;
    },
  },
  methods: {
    onChange(value) {
      this.$emit('input', value ? MEMBERSHIP_DESCENDANTS : MEMBERSHIP_ALL_AVAILABLE);
    },
  },
  I18N_SHOW_ONLY_INHERITED,
};
</script>

<template>
  <gl-toggle
    data-testid="runner-membership-toggle"
    :value="toggle"
    :label="$options.I18N_SHOW_ONLY_INHERITED"
    label-position="left"
    @change="onChange"
  />
</template>
