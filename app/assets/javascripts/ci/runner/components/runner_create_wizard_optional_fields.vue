<script>
import { GlForm, GlButton, GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import MultipleChoiceSelector from '~/vue_shared/components/multiple_choice_selector.vue';
import MultipleChoiceSelectorItem from '~/vue_shared/components/multiple_choice_selector_item.vue';
import {
  DEFAULT_ACCESS_LEVEL,
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
} from '../constants';

export default {
  components: {
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    MultiStepFormTemplate,
    MultipleChoiceSelector,
    MultipleChoiceSelectorItem,
  },
  props: {
    currentStep: {
      type: Number,
      required: true,
    },
    stepsTotal: {
      type: Number,
      required: true,
    },
    tags: {
      type: String,
      required: true,
    },
    runUntagged: {
      type: Boolean,
      required: true,
    },
    runnerType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      runner: {
        runnerType: this.runnerType,
        description: '',
        maintenanceNote: '',
        paused: false,
        accessLevel: DEFAULT_ACCESS_LEVEL,
        runUntagged: this.runUntagged,
        locked: false,
        tagList: this.tags,
        maximumTimeout: '',
      },
    };
  },
  methods: {
    onCheckboxesInput(checked) {
      if (checked.includes(ACCESS_LEVEL_REF_PROTECTED))
        this.runner.accessLevel = ACCESS_LEVEL_REF_PROTECTED;
      else this.runner.accessLevel = ACCESS_LEVEL_NOT_PROTECTED;

      this.runner.paused = checked.includes('paused');
    },
  },
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>
<template>
  <gl-form>
    <multi-step-form-template
      :title="s__('Runners|Optional configuration details')"
      :current-step="currentStep"
      :steps-total="stepsTotal"
    >
      <template #form>
        <multiple-choice-selector class="gl-mb-5" @input="onCheckboxesInput">
          <multiple-choice-selector-item
            :value="ACCESS_LEVEL_REF_PROTECTED"
            :title="s__('Runners|Protected')"
            :description="s__('Runners|Use the runner on pipelines for protected branches only.')"
          />
          <multiple-choice-selector-item
            value="paused"
            :title="s__('Runners|Paused')"
            :description="s__('Runners|Stop the runner from accepting new jobs.')"
          />
        </multiple-choice-selector>

        <gl-form-group
          label-for="runner-description"
          :label="s__('Runners|Runner description')"
          :optional="true"
        >
          <gl-form-input
            id="runner-description"
            v-model="runner.description"
            name="description"
            data-testid="runner-description-input"
          />
        </gl-form-group>

        <gl-form-group
          label-for="runner-maintenance-note"
          :label="s__('Runners|Maintenance note')"
          :label-description="
            s__('Runners|Add notes such as the runner owner or what it should be used for.')
          "
          :optional="true"
          :description="s__('Runners|Only administrators can view this.')"
        >
          <gl-form-textarea
            id="runner-maintenance-note"
            v-model="runner.maintenanceNote"
            name="maintenance-note"
            data-testid="runner-maintenance-note"
          />
        </gl-form-group>

        <gl-form-group
          label-for="max-timeout"
          :label="s__('Runners|Maximum job timeout')"
          :label-description="
            s__(
              'Runners|Maximum amount of time the runner can run before it terminates. If a project has a shorter job timeout period, the job timeout period of the instance runner is used instead.',
            )
          "
          :optional="true"
          :description="
            s__('Runners|Enter the job timeout in seconds. Must be a minimum of 600 seconds.')
          "
        >
          <gl-form-input
            id="max-timeout"
            v-model="runner.maximumTimeout"
            name="max-timeout"
            type="number"
            data-testid="max-timeout-input"
          />
        </gl-form-group>
      </template>
      <template #next>
        <!-- [Next step] button will be un-disabled in https://gitlab.com/gitlab-org/gitlab/-/issues/396544 -->
        <gl-button
          category="primary"
          variant="confirm"
          :disabled="true"
          type="submit"
          data-testid="next-button"
        >
          {{ __('Next step') }}
        </gl-button>
      </template>
      <template #back>
        <gl-button
          category="primary"
          variant="default"
          data-testid="back-button"
          @click="$emit('back')"
        >
          {{ __('Go back') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </gl-form>
</template>
