<script>
import { mapActions, mapState } from 'vuex';
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
import {
  NAME_REGEX_LENGTH,
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '../constants';
import { mapComputed } from '~/vuex_shared/bindings';

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
  labelsConfig: {
    cols: 3,
    align: 'right',
  },
  computed: {
    ...mapState(['formOptions', 'isLoading']),
    ...mapComputed(
      [
        'enabled',
        { key: 'cadence', getter: 'getCadence' },
        { key: 'older_than', getter: 'getOlderThan' },
        { key: 'keep_n', getter: 'getKeepN' },
        'name_regex',
      ],
      'updateSettings',
      'settings',
    ),
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
    nameRegexPlaceholder() {
      return '.*';
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
  },
  methods: {
    ...mapActions(['resetSettings', 'saveSettings']),
    submit() {
      this.saveSettings()
        .then(() => this.$toast.show(UPDATE_SETTINGS_SUCCESS_MESSAGE, { type: 'success' }))
        .catch(() => this.$toast.show(UPDATE_SETTINGS_ERROR_MESSAGE, { type: 'error' }));
    },
  },
};
</script>

<template>
  <form ref="form-element" @submit.prevent="submit" @reset.prevent="resetSettings">
    <gl-card>
      <template #header>
        {{ s__('ContainerRegistry|Tag expiration policy') }}
      </template>
      <template>
        <gl-form-group
          id="expiration-policy-toggle-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-toggle"
          :label="s__('ContainerRegistry|Expiration policy:')"
        >
          <div class="d-flex align-items-start">
            <gl-toggle id="expiration-policy-toggle" v-model="enabled" :disabled="isLoading" />
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
          <gl-form-select
            id="expiration-policy-interval"
            v-model="older_than"
            :disabled="isFormElementDisabled"
          >
            <option v-for="option in formOptions.olderThan" :key="option.key" :value="option.key">
              {{ option.label }}
            </option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          id="expiration-policy-schedule-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-schedule"
          :label="s__('ContainerRegistry|Expiration schedule:')"
        >
          <gl-form-select
            id="expiration-policy-schedule"
            v-model="cadence"
            :disabled="isFormElementDisabled"
          >
            <option v-for="option in formOptions.cadence" :key="option.key" :value="option.key">
              {{ option.label }}
            </option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          id="expiration-policy-latest-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-latest"
          :label="s__('ContainerRegistry|Number of tags to retain:')"
        >
          <gl-form-select
            id="expiration-policy-latest"
            v-model="keep_n"
            :disabled="isFormElementDisabled"
          >
            <option v-for="option in formOptions.keepN" :key="option.key" :value="option.key">
              {{ option.label }}
            </option>
          </gl-form-select>
        </gl-form-group>

        <gl-form-group
          id="expiration-policy-name-matching-group"
          :label-cols="$options.labelsConfig.cols"
          :label-align="$options.labelsConfig.align"
          label-for="expiration-policy-name-matching"
          :label="
            s__('ContainerRegistry|Docker tags with names matching this regex pattern will expire:')
          "
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
          <gl-button ref="cancel-button" type="reset" class="mr-2 d-block" :disabled="isLoading">
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
