<script>
import { uniqueId } from 'lodash';
import { GlFormGroup, GlToggle, GlFormSelect, GlFormTextarea } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { NAME_REGEX_LENGTH } from '../constants';
import { mapComputedToEvent } from '../utils';

export default {
  components: {
    GlFormGroup,
    GlToggle,
    GlFormSelect,
    GlFormTextarea,
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
  nameRegexPlaceholder: '.*',
  selectList: [
    {
      name: 'expiration-policy-interval',
      label: s__('ContainerRegistry|Expiration interval:'),
      model: 'older_than',
      optionKey: 'olderThan',
    },
    {
      name: 'expiration-policy-schedule',
      label: s__('ContainerRegistry|Expiration schedule:'),
      model: 'cadence',
      optionKey: 'cadence',
    },
    {
      name: 'expiration-policy-latest',
      label: s__('ContainerRegistry|Number of tags to retain:'),
      model: 'keep_n',
      optionKey: 'keepN',
    },
  ],
  data() {
    return {
      uniqueId: uniqueId(),
    };
  },
  computed: {
    ...mapComputedToEvent(['enabled', 'cadence', 'older_than', 'keep_n', 'name_regex'], 'value'),
    policyEnabledText() {
      return this.enabled ? __('enabled') : __('disabled');
    },
    toggleDescriptionText() {
      return sprintf(
        s__('ContainerRegistry|Docker tag expiration policy is %{toggleStatus}'),
        {
          toggleStatus: `<strong>${this.policyEnabledText}</strong>`,
        },
        false,
      );
    },
    regexHelpText() {
      return sprintf(
        s__(
          'ContainerRegistry|Wildcards such as %{codeStart}.*-stable%{codeEnd} or %{codeStart}production/.*%{codeEnd} are supported.  To select all tags, use %{codeStart}.*%{codeEnd}',
        ),
        {
          codeStart: '<code>',
          codeEnd: '</code>',
        },
        false,
      );
    },
    nameRegexState() {
      return this.name_regex ? this.name_regex.length <= NAME_REGEX_LENGTH : null;
    },
    fieldsValidity() {
      return this.nameRegexState !== false;
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
      :label="s__('ContainerRegistry|Expiration policy:')"
    >
      <div class="d-flex align-items-start">
        <gl-toggle
          :id="idGenerator('expiration-policy-toggle')"
          v-model="enabled"
          :disabled="isLoading"
        />
        <span class="mb-2 ml-1 lh-2" v-html="toggleDescriptionText"></span>
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
      :id="idGenerator('expiration-policy-name-matching-group')"
      :label-cols="labelCols"
      :label-align="labelAlign"
      :label-for="idGenerator('expiration-policy-name-matching')"
      :label="
        s__('ContainerRegistry|Docker tags with names matching this regex pattern will expire:')
      "
      :state="nameRegexState"
      :invalid-feedback="
        s__('ContainerRegistry|The value of this input should be less than 255 characters')
      "
    >
      <gl-form-textarea
        :id="idGenerator('expiration-policy-name-matching')"
        v-model="name_regex"
        :placeholder="$options.nameRegexPlaceholder"
        :state="nameRegexState"
        :disabled="isFormElementDisabled"
        trim
      />
      <template #description>
        <span ref="regex-description" v-html="regexHelpText"></span>
      </template>
    </gl-form-group>
  </div>
</template>
