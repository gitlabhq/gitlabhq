<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { placeholderForType } from 'jh_else_ce/integrations/constants';

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
  computed: {
    ...mapGetters(['isInheriting']),
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
      <gl-form-group v-for="event in events" :key="event.name" :description="event.description">
        <input :name="checkboxName(event.name)" type="hidden" :value="event.value || false" />
        <gl-form-checkbox v-model="event.value" :disabled="isInheriting">
          {{ event.title }}
        </gl-form-checkbox>
        <gl-form-input
          v-if="event.field"
          v-model="event.field.value"
          :name="fieldName(event.field.name)"
          :placeholder="event.field.placeholder || defaultPlaceholder"
          :readonly="isInheriting"
        />
      </gl-form-group>
    </div>
  </gl-form-group>
</template>
