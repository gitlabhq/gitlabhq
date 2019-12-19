<script>
import { mapActions } from 'vuex';
import { GlFormGroup, GlToggle, GlFormSelect, GlFormTextarea, GlButton } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { NAME_REGEX_LENGTH } from '../constants';
import { mapComputed } from '~/vuex_shared/bindings';

export default {
  components: {
    GlFormGroup,
    GlToggle,
    GlFormSelect,
    GlFormTextarea,
    GlButton,
  },
  labelsConfig: {
    cols: 3,
    align: 'right',
  },
  computed: {
    ...mapComputed('settings', 'updateSettings', [
      'enabled',
      'cadence',
      'older_than',
      'keep_n',
      'name_regex',
    ]),
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
          'ContainerRegistry|Wildcards such as %{codeStart}*-stable%{codeEnd} or %{codeStart}production/*%{codeEnd} are supported',
        ),
        {
          codeStart: '<code>',
          codeEnd: '</code>',
        },
        false,
      );
    },
    nameRegexPlaceholder() {
      return '.*';
    },
    nameRegexState() {
      return this.name_regex ? this.name_regex.length <= NAME_REGEX_LENGTH : null;
    },
    formIsValid() {
      return this.nameRegexState === false;
    },
  },
  methods: {
    ...mapActions(['resetSettings', 'saveSettings']),
  },
};
</script>

<template>
  <div class="card">
    <form ref="form-element" @submit.prevent="saveSettings" @reset.prevent="resetSettings">
      <div class="card-header">
        {{ s__('ContainerRegistry|Tag expiration policy') }}
      </div>
      <div class="card-body">
        <gl-form-group
          id="expiration-policy-toggle-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-toggle"
          :label="s__('ContainerRegistry|Expiration policy:')"
        >
          <div class="d-flex align-items-start">
            <gl-toggle id="expiration-policy-toggle" v-model="enabled" />
            <span class="mb-2 ml-1 lh-2" v-html="toggleDescriptionText"></span>
          </div>
        </gl-form-group>

        <gl-form-group
          id="expiration-policy-interval-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-interval"
          :label="s__('ContainerRegistry|Expiration interval:')"
        >
          <gl-form-select id="expiration-policy-interval" v-model="older_than">
            <option value="1">{{ __('Option 1') }}</option>
            <option value="2">{{ __('Option 2') }}</option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          id="expiration-policy-schedule-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-schedule"
          :label="s__('ContainerRegistry|Expiration schedule:')"
        >
          <gl-form-select id="expiration-policy-schedule" v-model="cadence">
            <option value="1">{{ __('Option 1') }}</option>
            <option value="2">{{ __('Option 2') }}</option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          id="expiration-policy-latest-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-latest"
          :label="s__('ContainerRegistry|Expiration latest:')"
        >
          <gl-form-select id="expiration-policy-latest" v-model="keep_n">
            <option value="1">{{ __('Option 1') }}</option>
            <option value="2">{{ __('Option 2') }}</option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          id="expiration-policy-name-matching-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-name-matching"
          :label="s__('ContainerRegistry|Expire Docker tags with name matching:')"
          :state="nameRegexState"
          :invalid-feedback="
            s__('ContainerRegistry|The value of this input should be less than 255 characters')
          "
        >
          <gl-form-textarea
            id="expiration-policy-name-matching"
            v-model="name_regex"
            :placeholder="nameRegexPlaceholder"
            :state="nameRegexState"
            trim
          />
          <template #description>
            <span ref="regex-description" v-html="regexHelpText"></span>
          </template>
        </gl-form-group>
      </div>
      <div class="card-footer text-right">
        <gl-button ref="cancel-button" type="reset">{{ __('Cancel') }}</gl-button>
        <gl-button ref="save-button" type="submit" :disabled="formIsValid" variant="success">
          {{ __('Save Expiration Policy') }}
        </gl-button>
      </div>
    </form>
  </div>
</template>
