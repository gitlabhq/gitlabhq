<script>
import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';

import {
  placeholderForType,
  integrationTriggerEventTitles,
} from 'any_else_ce/integrations/constants';

export default {
  name: 'TriggerField',
  components: {
    GlFormCheckbox,
    GlFormInput,
  },
  props: {
    event: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      value: false,
      fieldValue: this.event.field?.value,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
    name() {
      return `service[${this.event.name}]`;
    },
    fieldName() {
      return `service[${this.event.field?.name}]`;
    },
    title() {
      return integrationTriggerEventTitles[this.event.name];
    },
    defaultPlaceholder() {
      return placeholderForType[this.type];
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
    <div class="gl-ml-6">
      <gl-form-input
        v-if="event.field"
        v-show="value"
        v-model="fieldValue"
        :name="fieldName"
        :placeholder="event.field.placeholder || defaultPlaceholder"
        :readonly="isInheriting"
      />
    </div>
  </div>
</template>
