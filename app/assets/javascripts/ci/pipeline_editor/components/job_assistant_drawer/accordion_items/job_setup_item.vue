<script>
import {
  GlAccordionItem,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlTokenSelector,
  GlFormCombobox,
} from '@gitlab/ui';
import { i18n } from '../constants';

export default {
  i18n,
  components: {
    GlAccordionItem,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlFormCombobox,
    GlTokenSelector,
  },
  props: {
    tagOptions: {
      type: Array,
      required: true,
    },
    job: {
      type: Object,
      required: true,
    },
    isNameValid: {
      type: Boolean,
      required: true,
    },
    isScriptValid: {
      type: Boolean,
      required: true,
    },
    availableStages: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
};
</script>
<template>
  <gl-accordion-item :title="$options.i18n.JOB_SETUP" visible>
    <gl-form-group
      :invalid-feedback="$options.i18n.THIS_FIELD_IS_REQUIRED"
      :state="isNameValid"
      :label="$options.i18n.JOB_NAME"
      label-for="job-name-input"
    >
      <gl-form-input
        id="job-name-input"
        :value="job.name"
        :state="isNameValid"
        data-testid="job-name-input"
        @input="$emit('update-job', 'name', $event)"
      />
    </gl-form-group>
    <gl-form-combobox
      :value="job.stage"
      :token-list="availableStages"
      :label-text="$options.i18n.STAGE"
      data-testid="job-stage-input"
      @input="$emit('update-job', 'stage', $event)"
    />
    <gl-form-group
      :invalid-feedback="$options.i18n.THIS_FIELD_IS_REQUIRED"
      :state="isScriptValid"
      :label="$options.i18n.SCRIPT"
      label-for="job-script-input"
    >
      <gl-form-textarea
        id="job-script-input"
        :value="job.script"
        :state="isScriptValid"
        :no-resize="false"
        data-testid="job-script-input"
        @input="$emit('update-job', 'script', $event)"
      />
    </gl-form-group>
    <gl-form-group id="job-tags-input" :label="$options.i18n.TAGS">
      <gl-token-selector
        :dropdown-items="tagOptions"
        :selected-tokens="job.tags"
        aria-labelled-by="job-tags-input"
        data-testid="job-tags-input"
        @input="$emit('update-job', 'tags', $event)"
      />
    </gl-form-group>
  </gl-accordion-item>
</template>
