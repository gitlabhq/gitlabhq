<script>
import { uniqueId } from 'lodash';
import {
  GlFormGroup,
  GlToggle,
  GlFormSelect,
  GlFormTextarea,
  GlButton,
  GlCard,
  GlLoadingIcon,
} from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { NAME_REGEX_LENGTH } from '../constants';
import { mapComputedToEvent } from '../utils';

export default {
  components: {
    GlFormGroup,
    GlToggle,
    GlFormSelect,
    GlFormTextarea,
    GlButton,
    GlCard,
    GlLoadingIcon,
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
    disableCancelButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  nameRegexPlaceholder: '.*',
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
          'ContainerRegistry|Wildcards such as %{codeStart}*-stable%{codeEnd} or %{codeStart}production/*%{codeEnd} are supported.  To select all tags, use %{codeStart}.*%{codeEnd}',
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
    formIsInvalid() {
      return this.nameRegexState === false;
    },
    isFormElementDisabled() {
      return !this.enabled || this.isLoading;
    },
    isSubmitButtonDisabled() {
      return this.formIsInvalid || this.isLoading;
    },
    isCancelButtonDisabled() {
      return this.disableCancelButton || this.isLoading;
    },
  },
  methods: {
    idGenerator(id) {
      return `${id}_${this.uniqueId}`;
    },
  },
};
</script>

<template>
  <form
    ref="form-element"
    class="lh-2"
    @submit.prevent="$emit('submit')"
    @reset.prevent="$emit('reset')"
  >
    <gl-card>
      <template #header>
        {{ s__('ContainerRegistry|Tag expiration policy') }}
      </template>
      <template>
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
          :id="idGenerator('expiration-policy-interval-group')"
          :label-cols="labelCols"
          :label-align="labelAlign"
          :label-for="idGenerator('expiration-policy-interval')"
          :label="s__('ContainerRegistry|Expiration interval:')"
        >
          <gl-form-select
            :id="idGenerator('expiration-policy-interval')"
            v-model="older_than"
            :disabled="isFormElementDisabled"
          >
            <option v-for="option in formOptions.olderThan" :key="option.key" :value="option.key">
              {{ option.label }}
            </option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          :id="idGenerator('expiration-policy-schedule-group')"
          :label-cols="labelCols"
          :label-align="labelAlign"
          :label-for="idGenerator('expiration-policy-schedule')"
          :label="s__('ContainerRegistry|Expiration schedule:')"
        >
          <gl-form-select
            :id="idGenerator('expiration-policy-schedule')"
            v-model="cadence"
            :disabled="isFormElementDisabled"
          >
            <option v-for="option in formOptions.cadence" :key="option.key" :value="option.key">
              {{ option.label }}
            </option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          :id="idGenerator('expiration-policy-latest-group')"
          :label-cols="labelCols"
          :label-align="labelAlign"
          :label-for="idGenerator('expiration-policy-latest')"
          :label="s__('ContainerRegistry|Number of tags to retain:')"
        >
          <gl-form-select
            :id="idGenerator('expiration-policy-latest')"
            v-model="keep_n"
            :disabled="isFormElementDisabled"
          >
            <option v-for="option in formOptions.keepN" :key="option.key" :value="option.key">
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
      </template>
      <template #footer>
        <div class="d-flex justify-content-end">
          <gl-button
            ref="cancel-button"
            type="reset"
            class="mr-2 d-block"
            :disabled="isCancelButtonDisabled"
          >
            {{ __('Cancel') }}
          </gl-button>
          <gl-button
            ref="save-button"
            type="submit"
            :disabled="isSubmitButtonDisabled"
            variant="success"
            class="d-flex justify-content-center align-items-center js-no-auto-disable"
          >
            {{ __('Save expiration policy') }}
            <gl-loading-icon v-if="isLoading" class="ml-2" />
          </gl-button>
        </div>
      </template>
    </gl-card>
  </form>
</template>
