<script>
import { uniqueId } from 'lodash';
import { GlFormGroup, GlToggle, GlFormSelect, GlFormTextarea, GlSprintf } from '@gitlab/ui';
import {
  NAME_REGEX_LENGTH,
  ENABLED_TEXT,
  DISABLED_TEXT,
  TEXT_AREA_INVALID_FEEDBACK,
  EXPIRATION_INTERVAL_LABEL,
  EXPIRATION_SCHEDULE_LABEL,
  KEEP_N_LABEL,
  NAME_REGEX_LABEL,
  NAME_REGEX_PLACEHOLDER,
  NAME_REGEX_DESCRIPTION,
  NAME_REGEX_KEEP_LABEL,
  NAME_REGEX_KEEP_PLACEHOLDER,
  NAME_REGEX_KEEP_DESCRIPTION,
  ENABLE_TOGGLE_LABEL,
  ENABLE_TOGGLE_DESCRIPTION,
} from '../constants';
import { mapComputedToEvent } from '../utils';

export default {
  components: {
    GlFormGroup,
    GlToggle,
    GlFormSelect,
    GlFormTextarea,
    GlSprintf,
  },
  props: {
    formOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    apiErrors: {
      type: Object,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    labelCols: {
      type: [Number, String],
      required: false,
      default: 3,
    },
    labelAlign: {
      type: String,
      required: false,
      default: 'right',
    },
  },
  i18n: {
    ENABLE_TOGGLE_LABEL,
    ENABLE_TOGGLE_DESCRIPTION,
  },
  selectList: [
    {
      name: 'expiration-policy-interval',
      label: EXPIRATION_INTERVAL_LABEL,
      model: 'older_than',
      optionKey: 'olderThan',
    },
    {
      name: 'expiration-policy-schedule',
      label: EXPIRATION_SCHEDULE_LABEL,
      model: 'cadence',
      optionKey: 'cadence',
    },
    {
      name: 'expiration-policy-latest',
      label: KEEP_N_LABEL,
      model: 'keep_n',
      optionKey: 'keepN',
    },
  ],
  textAreaList: [
    {
      name: 'expiration-policy-name-matching',
      label: NAME_REGEX_LABEL,
      model: 'name_regex',
      placeholder: NAME_REGEX_PLACEHOLDER,
      description: NAME_REGEX_DESCRIPTION,
    },
    {
      name: 'expiration-policy-keep-name',
      label: NAME_REGEX_KEEP_LABEL,
      model: 'name_regex_keep',
      placeholder: NAME_REGEX_KEEP_PLACEHOLDER,
      description: NAME_REGEX_KEEP_DESCRIPTION,
    },
  ],
  data() {
    return {
      uniqueId: uniqueId(),
    };
  },
  computed: {
    ...mapComputedToEvent(
      ['enabled', 'cadence', 'older_than', 'keep_n', 'name_regex', 'name_regex_keep'],
      'value',
    ),
    policyEnabledText() {
      return this.enabled ? ENABLED_TEXT : DISABLED_TEXT;
    },
    textAreaValidation() {
      const nameRegexErrors =
        this.apiErrors?.name_regex || this.validateRegexLength(this.name_regex);
      const nameKeepRegexErrors =
        this.apiErrors?.name_regex_keep || this.validateRegexLength(this.name_regex_keep);

      return {
        /*
         * The state has this form:
         * null: gray border, no message
         * true: green border, no message ( because none is configured)
         * false: red border, error message
         * So in this function we keep null if the are no message otherwise we 'invert' the error message
         */
        name_regex: {
          state: nameRegexErrors === null ? null : !nameRegexErrors,
          message: nameRegexErrors,
        },
        name_regex_keep: {
          state: nameKeepRegexErrors === null ? null : !nameKeepRegexErrors,
          message: nameKeepRegexErrors,
        },
      };
    },
    fieldsValidity() {
      return (
        this.textAreaValidation.name_regex.state !== false &&
        this.textAreaValidation.name_regex_keep.state !== false
      );
    },
    isFormElementDisabled() {
      return !this.enabled || this.isLoading;
    },
  },
  watch: {
    fieldsValidity: {
      immediate: true,
      handler(valid) {
        if (valid) {
          this.$emit('validated');
        } else {
          this.$emit('invalidated');
        }
      },
    },
  },
  methods: {
    validateRegexLength(value) {
      if (!value) {
        return null;
      }
      return value.length <= NAME_REGEX_LENGTH ? '' : TEXT_AREA_INVALID_FEEDBACK;
    },
    idGenerator(id) {
      return `${id}_${this.uniqueId}`;
    },
    updateModel(value, key) {
      this[key] = value;
    },
  },
};
</script>

<template>
  <div ref="form-elements" class="lh-2">
    <gl-form-group
      :id="idGenerator('expiration-policy-toggle-group')"
      :label-cols="labelCols"
      :label-align="labelAlign"
      :label-for="idGenerator('expiration-policy-toggle')"
      :label="$options.i18n.ENABLE_TOGGLE_LABEL"
    >
      <div class="d-flex align-items-start">
        <gl-toggle
          :id="idGenerator('expiration-policy-toggle')"
          v-model="enabled"
          :disabled="isLoading"
        />
        <span class="mb-2 ml-2 lh-2">
          <gl-sprintf :message="$options.i18n.ENABLE_TOGGLE_DESCRIPTION">
            <template #toggleStatus>
              <strong>{{ policyEnabledText }}</strong>
            </template>
          </gl-sprintf>
        </span>
      </div>
    </gl-form-group>

    <gl-form-group
      v-for="select in $options.selectList"
      :id="idGenerator(`${select.name}-group`)"
      :key="select.name"
      :label-cols="labelCols"
      :label-align="labelAlign"
      :label-for="idGenerator(select.name)"
      :label="select.label"
    >
      <gl-form-select
        :id="idGenerator(select.name)"
        :value="value[select.model]"
        :disabled="isFormElementDisabled"
        @input="updateModel($event, select.model)"
      >
        <option
          v-for="option in formOptions[select.optionKey]"
          :key="option.key"
          :value="option.key"
        >
          {{ option.label }}
        </option>
      </gl-form-select>
    </gl-form-group>

    <gl-form-group
      v-for="textarea in $options.textAreaList"
      :id="idGenerator(`${textarea.name}-group`)"
      :key="textarea.name"
      :label-cols="labelCols"
      :label-align="labelAlign"
      :label-for="idGenerator(textarea.name)"
      :state="textAreaValidation[textarea.model].state"
      :invalid-feedback="textAreaValidation[textarea.model].message"
    >
      <template #label>
        <gl-sprintf :message="textarea.label">
          <template #italic="{content}">
            <i>{{ content }}</i>
          </template>
        </gl-sprintf>
      </template>
      <gl-form-textarea
        :id="idGenerator(textarea.name)"
        :value="value[textarea.model]"
        :placeholder="textarea.placeholder"
        :state="textAreaValidation[textarea.model].state"
        :disabled="isFormElementDisabled"
        trim
        @input="updateModel($event, textarea.model)"
      />
      <template #description>
        <span ref="regex-description">
          <gl-sprintf :message="textarea.description">
            <template #code="{content}">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </span>
      </template>
    </gl-form-group>
  </div>
</template>
