<script>
/* eslint-disable vue/no-v-html */
import { GlFormGroup, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormTextarea } from '@gitlab/ui';
import { capitalize, lowerCase, isEmpty } from 'lodash';
import { mapGetters } from 'vuex';
import eventHub from '../event_hub';

export default {
  name: 'DynamicField',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
  },
  props: {
    choices: {
      type: Array,
      required: false,
      default: null,
    },
    help: {
      type: String,
      required: false,
      default: null,
    },
    name: {
      type: String,
      required: true,
    },
    placeholder: {
      type: String,
      required: false,
      default: null,
    },
    required: {
      type: Boolean,
      required: false,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
    type: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      model: this.value,
      validated: false,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
    isCheckbox() {
      return this.type === 'checkbox';
    },
    isPassword() {
      return this.type === 'password';
    },
    isSelect() {
      return this.type === 'select';
    },
    isTextarea() {
      return this.type === 'textarea';
    },
    isNonEmptyPassword() {
      return this.isPassword && !isEmpty(this.value);
    },
    humanizedTitle() {
      return this.title || capitalize(lowerCase(this.name));
    },
    passwordRequired() {
      return isEmpty(this.value) && this.required;
    },
    options() {
      return this.choices.map((choice) => {
        return {
          value: choice[1],
          text: choice[0],
        };
      });
    },
    fieldId() {
      return `service_${this.name}`;
    },
    fieldName() {
      return `service[${this.name}]`;
    },
    sharedProps() {
      return {
        id: this.fieldId,
        name: this.fieldName,
        state: this.valid,
        readonly: this.isInheriting,
      };
    },
    valid() {
      return !this.required || !isEmpty(this.model) || this.isNonEmptyPassword || !this.validated;
    },
  },
  created() {
    if (this.isNonEmptyPassword) {
      this.model = null;
    }
    eventHub.$on('validateForm', this.validateForm);
  },
  beforeDestroy() {
    eventHub.$off('validateForm', this.validateForm);
  },
  methods: {
    validateForm() {
      this.validated = true;
    },
  },
};
</script>

<template>
  <gl-form-group
    :label="humanizedTitle"
    :label-for="fieldId"
    :invalid-feedback="__('This field is required.')"
    :state="valid"
  >
    <template #description>
      <span v-html="help"></span>
    </template>

    <template v-if="isCheckbox">
      <input :name="fieldName" type="hidden" :value="model || false" />
      <gl-form-checkbox :id="fieldId" v-model="model" :disabled="isInheriting">
        {{ humanizedTitle }}
      </gl-form-checkbox>
    </template>
    <template v-else-if="isSelect">
      <input type="hidden" :name="fieldName" :value="model" />
      <gl-form-select :id="fieldId" v-model="model" :options="options" :disabled="isInheriting" />
    </template>
    <gl-form-textarea
      v-else-if="isTextarea"
      v-model="model"
      v-bind="sharedProps"
      :placeholder="placeholder"
      :required="required"
    />
    <gl-form-input
      v-else-if="isPassword"
      v-model="model"
      v-bind="sharedProps"
      :type="type"
      autocomplete="new-password"
      :placeholder="placeholder"
      :required="passwordRequired"
      :data-qa-selector="`${fieldId}_field`"
    />
    <gl-form-input
      v-else
      v-model="model"
      v-bind="sharedProps"
      :type="type"
      :placeholder="placeholder"
      :required="required"
      :data-qa-selector="`${fieldId}_field`"
    />
  </gl-form-group>
</template>
