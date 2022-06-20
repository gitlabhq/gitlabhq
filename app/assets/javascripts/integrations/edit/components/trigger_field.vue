<script>
import { GlFormCheckbox } from '@gitlab/ui';
import { mapGetters } from 'vuex';

import { integrationTriggerEventTitles } from '~/integrations/constants';

export default {
  name: 'TriggerField',
  components: {
    GlFormCheckbox,
  },
  props: {
    event: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      value: false,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
    name() {
      return `service[${this.event.name}]`;
    },
    title() {
      return integrationTriggerEventTitles[this.event.name];
    },
  },
  mounted() {
    this.value = this.event.value || false;
  },
};
</script>

<template>
  <div>
    <input :name="name" type="hidden" :value="value" />
    <gl-form-checkbox v-model="value" :disabled="isInheriting">
      {{ title }}
    </gl-form-checkbox>
  </div>
</template>
