<script>
import { mapState } from 'pinia';

import { useIntegrationForm } from '../../store';
import TriggerField from '../trigger_field.vue';

export default {
  name: 'IntegrationSectionTrigger',
  components: {
    TriggerField,
  },
  computed: {
    ...mapState(useIntegrationForm, ['currentKey', 'propsSource']),
  },
};
</script>

<template>
  <div data-testid="trigger-fields-group">
    <trigger-field
      v-for="event in propsSource.triggerEvents"
      :key="`${currentKey}-trigger-fields-${event.name}`"
      :event="event"
      :type="propsSource.type"
      class="gl-mb-3"
    />
  </div>
</template>
