<script>
import eventHub from '../event_hub';
import { capitalize, lowerCase, isEmpty } from 'lodash';
import { __, sprintf } from '~/locale';
import { GlFormGroup, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormTextarea } from '@gitlab/ui';

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
    label() {
      if (this.isNonEmptyPassword) {
        return sprintf(__('Enter new %{field_title}'), {
          field_title: this.humanizedTitle,
        });
      }
      return this.humanizedTitle;
    },
    humanizedTitle() {
      return this.title || capitalize(lowerCase(this.name));
    },
    passwordRequired() {
      return isEmpty(this.value) && this.required;
    },
    options() {
      return this.choices.map(choice => {
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
      };
    },
    valid() {
      return !this.required || !isEmpty(this.model) || !this.validated;
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
    :label="label"
    :label-for="fieldId"
    :invalid-feedback="__('This field is required.')"
    :state="valid"
    :description="help"
  >
    <template v-if="isCheckbox">
      <input :name="fieldName" type="hidden" value="false" />
      <gl-form-checkbox v-model="model" v-bind="sharedProps">
        {{ humanizedTitle }}
      </gl-form-checkbox>
    </template>
    <gl-form-select v-else-if="isSelect" v-model="model" v-bind="sharedProps" :options="options" />
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
    />
    <gl-form-input
      v-else
      v-model="model"
      v-bind="sharedProps"
      :type="type"
      :placeholder="placeholder"
      :required="required"
    />
  </gl-form-group>
</template>
