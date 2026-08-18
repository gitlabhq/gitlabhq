<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { mapState } from 'pinia';
import { placeholderForType } from 'jh_else_ce/integrations/constants';
import { useIntegrationForm } from '../store';

export default {
  name: 'TriggerFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
  },
  props: {
    events: {
      type: Array,
      required: false,
      default: null,
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      localEvents: (this.events || []).map((event) => ({
        ...event,
        value: event.value || false,
        fieldValue: event.field?.value,
      })),
    };
  },
  computed: {
    ...mapState(useIntegrationForm, ['isInheriting']),
    defaultPlaceholder() {
      return placeholderForType[this.type];
    },
  },
  methods: {
    checkboxName(name) {
      return `service[${name}]`;
    },
    fieldName(name) {
      return `service[${name}]`;
    },
  },
};
</script>

<template>
  <gl-form-group
    :label="__('Trigger')"
    label-for="trigger-fields"
    data-testid="trigger-fields-group"
  >
    <div id="trigger-fields">
      <gl-form-group
        v-for="event in localEvents"
        :key="event.name"
        :description="event.description"
      >
        <input :name="checkboxName(event.name)" type="hidden" :value="event.value" />
        <gl-form-checkbox v-model="event.value" :disabled="isInheriting">
          {{ event.title }}
        </gl-form-checkbox>
        <gl-form-input
          v-if="event.field"
          v-model="event.fieldValue"
          :name="fieldName(event.field.name)"
          :placeholder="event.field.placeholder || defaultPlaceholder"
          :readonly="isInheriting"
        />
      </gl-form-group>
    </div>
  </gl-form-group>
</template>
