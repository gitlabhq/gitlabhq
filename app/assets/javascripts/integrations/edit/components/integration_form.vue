<script>
import ActiveToggle from './active_toggle.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';

export default {
  name: 'IntegrationForm',
  components: {
    ActiveToggle,
    JiraTriggerFields,
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
  </div>
</template>
