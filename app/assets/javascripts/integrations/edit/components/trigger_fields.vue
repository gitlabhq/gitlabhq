<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { startCase } from 'lodash';
import { mapGetters } from 'vuex';
import { __ } from '~/locale';

const typeWithPlaceholder = {
  SLACK: 'slack',
  MATTERMOST: 'mattermost',
};

const placeholderForType = {
  [typeWithPlaceholder.SLACK]: __('#general, #development'),
  [typeWithPlaceholder.MATTERMOST]: __('my-channel'),
};

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
    placeholder() {
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
    startCase,
  },
};
</script>

<template>
  <gl-form-group
    class="gl-pt-3"
    :label="__('Trigger')"
    label-for="trigger-fields"
    data-testid="trigger-fields-group"
  >
    <div id="trigger-fields" class="gl-pt-3">
      <gl-form-group v-for="event in events" :key="event.title" :description="event.description">
        <input :name="checkboxName(event.name)" type="hidden" :value="event.value || false" />
        <gl-form-checkbox v-model="event.value" :disabled="isInheriting">
          {{ startCase(event.title) }}
        </gl-form-checkbox>
        <gl-form-input
          v-if="event.field"
          v-model="event.field.value"
          :name="fieldName(event.field.name)"
          :placeholder="placeholder"
          :readonly="isInheriting"
        />
      </gl-form-group>
    </div>
  </gl-form-group>
</template>
