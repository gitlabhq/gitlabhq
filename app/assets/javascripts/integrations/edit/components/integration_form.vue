<script>
import ActiveToggle from './active_toggle.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import TriggerFields from './trigger_fields.vue';

export default {
  name: 'IntegrationForm',
  components: {
    ActiveToggle,
    JiraTriggerFields,
    TriggerFields,
  },
  props: {
    activeToggleProps: {
      type: Object,
      required: true,
    },
    showActive: {
      type: Boolean,
      required: true,
    },
    triggerFieldsProps: {
      type: Object,
      required: true,
    },
    triggerEvents: {
      type: Array,
      required: false,
      default: () => [],
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    isJira() {
      return this.type === 'jira';
    },
  },
};
</script>

<template>
  <div>
    <active-toggle v-if="showActive" v-bind="activeToggleProps" />
    <jira-trigger-fields v-if="isJira" v-bind="triggerFieldsProps" />
    <trigger-fields v-else-if="triggerEvents.length" :events="triggerEvents" :type="type" />
  </div>
</template>
