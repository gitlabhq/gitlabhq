<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';

import DynamicField from '../dynamic_field.vue';

export default {
  name: 'IntegrationSectionConfiguration',
  components: {
    DynamicField,
  },
  props: {
    fieldClass: {
      type: String,
      required: false,
      default: null,
    },
    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
    isValidated: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['currentKey']),
  },
};
</script>

<template>
  <div>
    <dynamic-field
      v-for="field in fields"
      :key="`${currentKey}-${field.name}`"
      v-bind="field"
      :field-class="fieldClass"
      :is-validated="isValidated"
      @update="$emit('update', { value: $event, field })"
    />
  </div>
</template>
