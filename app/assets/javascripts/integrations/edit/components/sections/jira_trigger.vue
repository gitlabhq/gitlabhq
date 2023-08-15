<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';

import JiraTriggerFields from '../jira_trigger_fields.vue';

export default {
  name: 'IntegrationSectionJiraTrigger',
  components: {
    JiraTriggerFields,
  },
  props: {
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
    <jira-trigger-fields
      :key="`${currentKey}-jira-trigger-fields`"
      v-bind="propsSource.triggerFieldsProps"
      :is-validated="isValidated"
    />
  </div>
</template>
