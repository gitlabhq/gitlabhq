<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormTextarea } from '@gitlab/ui';
import { capitalize, lowerCase, isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'DynamicField',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
  },
  directives: {
    SafeHtml,
  },
  props: {
    fieldClass: {
      type: String,
      required: false,
      default: null,
    },
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
    labelDescription: {
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
    /**
     * The label that is displayed inline with the checkbox.
     */
    checkboxLabel: {
      type: String,
      required: false,
      default: null,
    },
    isValidated: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      model: this.value,
    };
  },
  computed: {
    ...mapGetters(['isInheriting', 'propsSource']),
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
      return this.choices?.map((choice) => {
        return {
          value: choice[1],
          text: choice[0],
        };
      });
    },
    fieldId() {
      return `service-${this.name}`;
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
        disabled: this.isDisabled,
      };
    },
    valid() {
      return !this.required || !isEmpty(this.model) || this.isNonEmptyPassword || !this.isValidated;
    },
    isInheritingOrDisabled() {
      return this.isInheriting || this.isDisabled;
    },
    isDisabled() {
      return !this.propsSource.editable;
    },
  },
  watch: {
    model(newValue) {
      this.$emit('update', newValue);
    },
  },
  created() {
    if (this.isNonEmptyPassword) {
      this.model = null;
    }
  },
};
</script>

<template>
  <gl-form-group
    :label="humanizedTitle"
    :label-description="labelDescription"
    :label-for="fieldId"
    :invalid-feedback="__('This field is required.')"
    :state="valid"
    :class="fieldClass"
  >
    <template v-if="!isCheckbox" #description>
      <span v-safe-html="help"></span>
    </template>

    <template v-if="isCheckbox">
      <input :name="fieldName" type="hidden" :value="model || false" />
      <gl-form-checkbox :id="fieldId" v-model="model" :disabled="isInheritingOrDisabled">
        {{ checkboxLabel || humanizedTitle }}
        <template #help>
          <span v-safe-html="help"></span>
        </template>
      </gl-form-checkbox>
    </template>
    <template v-else-if="isSelect">
      <input type="hidden" :name="fieldName" :value="model" />
      <gl-form-select
        :id="fieldId"
        v-model="model"
        :options="options"
        :disabled="isInheritingOrDisabled"
      />
    </template>
    <gl-form-textarea
      v-else-if="isTextarea"
      v-model="model"
      v-bind="sharedProps"
      no-resize
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
      :data-testid="`${fieldId}-field`"
    />
    <gl-form-input
      v-else
      v-model="model"
      v-bind="sharedProps"
      :type="type"
      :placeholder="placeholder"
      :required="required"
      :data-testid="`${fieldId}-field`"
    />
  </gl-form-group>
</template>
