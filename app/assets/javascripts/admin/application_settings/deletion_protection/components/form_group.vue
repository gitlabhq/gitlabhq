<script>
import { GlFormGroup, GlFormInput, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  I18N_DELETION_PROTECTION,
  DEL_ADJ_PERIOD_MAX_LIMIT_ERROR,
  DEL_ADJ_PERIOD_MIN_LIMIT_ERROR,
  DEL_ADJ_PERIOD_MAX_LIMIT,
  DEL_ADJ_PERIOD_MIN_LIMIT,
} from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlLink,
  },
  props: {
    deletionAdjournedPeriod: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      formData: {
        deletionAdjournedPeriod: this.deletionAdjournedPeriod,
      },
      invalidFeedback: '',
    };
  },
  i18n: I18N_DELETION_PROTECTION,
  helpPath: helpPagePath('administration/settings/visibility_and_access_controls', {
    anchor: 'delayed-project-deletion',
  }),
  inputId: 'application_setting_deletion_adjourned_period',
  computed: {
    state() {
      return this.invalidFeedback !== '' ? false : null;
    },
  },
  methods: {
    validate() {
      if (this.formData.deletionAdjournedPeriod > DEL_ADJ_PERIOD_MAX_LIMIT) {
        this.invalidFeedback = DEL_ADJ_PERIOD_MAX_LIMIT_ERROR;
        return;
      }
      if (this.formData.deletionAdjournedPeriod < DEL_ADJ_PERIOD_MIN_LIMIT) {
        this.invalidFeedback = DEL_ADJ_PERIOD_MIN_LIMIT_ERROR;
        return;
      }
      this.invalidFeedback = '';
    },
    onBlur() {
      this.validate();
    },
    onInvalid() {
      this.validate();
      this.$refs.formInput.$el.focus();
    },
  },
};
</script>
<template>
  <gl-form-group
    :label="$options.i18n.label"
    :label-for="$options.inputId"
    :state="state"
    :invalid-feedback="invalidFeedback"
  >
    <template #label-description>
      <span>{{ $options.i18n.helpText }}</span>
      <gl-link :href="$options.helpPath" target="_blank">{{ $options.i18n.learnMore }}</gl-link>
    </template>
    <div data-testid="deletion_adjourned_period_group" class="gl-flex gl-items-center">
      <gl-form-input
        :id="$options.inputId"
        ref="formInput"
        v-model="formData.deletionAdjournedPeriod"
        name="application_setting[deletion_adjourned_period]"
        data-testid="deletion_adjourned_period"
        width="xs"
        type="number"
        :min="1"
        :max="90"
        :state="state"
        @blur="onBlur"
        @invalid.prevent="onInvalid"
      />
      <span class="gl-ml-3">{{ $options.i18n.days }}</span>
    </div>
  </gl-form-group>
</template>
