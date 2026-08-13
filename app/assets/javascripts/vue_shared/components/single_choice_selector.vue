<script>
import { GlFormRadioGroup } from '@gitlab/ui';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'SingleChoiceSelector',
  components: { GlFormRadioGroup },
  mixins: [glSlotsMixin],
  props: {
    checked: {
      type: String,
      required: false,
      default: undefined,
    },
    name: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  emits: ['change'],
  methods: {
    onChange(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <gl-form-radio-group
    :checked="checked"
    :name="name"
    class="multiple-choice-selector gl-border gl-block gl-rounded-base"
    @change="onChange"
  >
    <template v-if="glSlots().default" #default><slot></slot></template>
  </gl-form-radio-group>
</template>
