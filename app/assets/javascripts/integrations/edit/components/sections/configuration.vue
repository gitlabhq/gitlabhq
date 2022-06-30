<script>
import { mapGetters } from 'vuex';

import DynamicField from '../dynamic_field.vue';

export default {
  name: 'IntegrationSectionConfiguration',
  components: {
    DynamicField,
  },
  props: {
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
      :is-validated="isValidated"
      :data-qa-selector="`${field.name}_div`"
    />
  </div>
</template>
