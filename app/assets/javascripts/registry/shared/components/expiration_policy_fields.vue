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
    textAreaInvalidFeedback: TEXT_AREA_INVALID_FEEDBACK,
    enableToggleLabel: ENABLE_TOGGLE_LABEL,
    enableToggleDescription: ENABLE_TOGGLE_DESCRIPTION,
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
      stateVariable: 'nameRegexState',
      description: NAME_REGEX_DESCRIPTION,
    },
    {
      name: 'expiration-policy-keep-name',
      label: NAME_REGEX_KEEP_LABEL,
      model: 'name_regex_keep',
      placeholder: NAME_REGEX_KEEP_PLACEHOLDER,
      stateVariable: 'nameKeepRegexState',
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
    textAreaState() {
      return {
        nameRegexState: this.validateNameRegex(this.name_regex),
        nameKeepRegexState: this.validateNameRegex(this.name_regex_keep),
      };
    },
    fieldsValidity() {
      return (
        this.textAreaState.nameRegexState !== false &&
        this.textAreaState.nameKeepRegexState !== false
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
    validateNameRegex(value) {
      return value ? value.length <= NAME_REGEX_LENGTH : null;
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
      :label="$options.i18n.enableToggleLabel"
    >
      <div class="d-flex align-items-start">
        <gl-toggle
          :id="idGenerator('expiration-policy-toggle')"
          v-model="enabled"
          :disabled="isLoading"
        />
        <span class="mb-2 ml-1 lh-2">
          <gl-sprintf :message="$options.i18n.enableToggleDescription">
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
      :state="textAreaState[textarea.stateVariable]"
      :invalid-feedback="$options.i18n.textAreaInvalidFeedback"
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
        :state="textAreaState[textarea.stateVariable]"
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
