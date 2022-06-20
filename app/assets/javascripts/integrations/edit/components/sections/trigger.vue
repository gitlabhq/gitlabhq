<script>
import { mapGetters } from 'vuex';

import TriggerField from '../trigger_field.vue';

export default {
  name: 'IntegrationSectionTrigger',
  components: {
    TriggerField,
  },
  computed: {
    ...mapGetters(['currentKey', 'propsSource']),
  },
};
</script>

<template>
  <div>
    <trigger-field
      v-for="event in propsSource.triggerEvents"
      :key="`${currentKey}-trigger-fields-${event.name}`"
      :event="event"
      class="gl-mb-3"
    />
  </div>
</template>
