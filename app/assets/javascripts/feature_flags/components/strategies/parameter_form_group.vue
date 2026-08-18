<script>
import { GlFormGroup } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'ParameterFormGroup',
  components: {
    GlFormGroup,
  },
  mixins: [glSlotsMixin],
  props: {
    inputId: {
      required: false,
      type: String,
      default: () => uniqueId('feature_flag_strategies_'),
    },
  },
};
</script>
<template>
  <gl-form-group :label-for="inputId" v-bind="$attrs">
    <template v-if="glSlots().default" #default><slot v-bind="{ inputId }"></slot></template>
  </gl-form-group>
</template>
