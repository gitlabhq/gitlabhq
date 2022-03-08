<script>
import { mapGetters } from 'vuex';

import ActiveCheckbox from '../active_checkbox.vue';
import DynamicField from '../dynamic_field.vue';

export default {
  name: 'IntegrationSectionConnection',
  components: {
    ActiveCheckbox,
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
    ...mapGetters(['currentKey', 'propsSource']),
  },
};
</script>

<template>
  <div>
    <active-checkbox
      v-if="propsSource.showActive"
      :key="`${currentKey}-active-checkbox`"
      @toggle-integration-active="$emit('toggle-integration-active', $event)"
    />
    <dynamic-field
      v-for="field in fields"
      :key="`${currentKey}-${field.name}`"
      v-bind="field"
      :is-validated="isValidated"
    />
  </div>
</template>
