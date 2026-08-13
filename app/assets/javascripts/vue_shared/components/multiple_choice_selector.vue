<script>
import { GlFormCheckboxGroup } from '@gitlab/ui';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'MultipleChoiceSelector',
  components: { GlFormCheckboxGroup },
  mixins: [glSlotsMixin],
  model: {
    prop: 'checked',
    event: 'input',
  },
  props: {
    checked: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['input'],
};
</script>

<template>
  <div class="multiple-choice-selector gl-border gl-block gl-rounded-base">
    <gl-form-checkbox-group :checked="checked" @input="$emit('input', $event)">
      <template v-if="glSlots().default" #default><slot></slot></template>
    </gl-form-checkbox-group>
  </div>
</template>
