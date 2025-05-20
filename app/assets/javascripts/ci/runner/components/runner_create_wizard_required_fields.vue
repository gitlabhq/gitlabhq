<script>
import { GlButton, GlFormGroup, GlFormInput, GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import MultipleChoiceSelector from '~/vue_shared/components/multiple_choice_selector.vue';
import MultipleChoiceSelectorItem from '~/vue_shared/components/multiple_choice_selector_item.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
    GlLink,
    GlAlert,
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
    isRunUntagged: {
      type: Boolean,
      required: true,
    },
    tagList: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      runUntagged: this.isRunUntagged,
      tags: this.tagList,
      isValidationAlertVisible: false,
    };
  },
  computed: {
    runUntaggedSelectorDefaultSelection() {
      return this.runUntagged ? ['untagged'] : [];
    },
  },
  methods: {
    onNext() {
      if (this.runUntagged || this.tags !== '') {
        this.isValidationAlertVisible = false;
        this.$emit('onRequiredFieldsUpdate', { tags: this.tags, runUntagged: this.runUntagged });
        this.$emit('next');
      } else {
        this.isValidationAlertVisible = true;
      }
    },
    onUntaggedInput(checked) {
      this.runUntagged = checked.includes('untagged');
    },
  },
  HELP_LABELS_PAGE_PATH: helpPagePath('ci/runners/configure_runners', {
    anchor: 'control-jobs-that-a-runner-can-run',
  }),
};
</script>
<template>
  <multi-step-form-template
    :title="s__('Runners|Create instance runner')"
    :current-step="currentStep"
    :steps-total="stepsTotal"
  >
    <template #form>
      <gl-alert
        v-if="isValidationAlertVisible"
        :dismissible="false"
        variant="danger"
        class="gl-mb-5"
        >{{
          s__(
            'Runners|To move to the next step, add at least one tag and/or enable the runner to pick up untagged jobs.',
          )
        }}</gl-alert
      >
      <gl-form-group :label="__('Tags')" label-for="runner-tags">
        <template #description>
          <gl-sprintf
            :message="s__('Runners|Separate multiple tags with a comma. For example, %{example}.')"
          >
            <template #example>
              <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
              <code>macos, shared</code>
            </template>
          </gl-sprintf>
        </template>
        <template #label-description>
          <gl-sprintf
            :message="
              s__(
                'Runners|Add tags to specify jobs that the runner can run. %{helpLinkStart}Learn more%{helpLinkEnd}.',
              )
            "
          >
            <template #helpLink="{ content }">
              <gl-link :href="$options.HELP_LABELS_PAGE_PATH" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
        <gl-form-input
          id="runner-tags"
          v-model="tags"
          name="tags"
          data-testid="runner-tags-input"
        />
      </gl-form-group>

      <multiple-choice-selector
        data-testid="runner-untagged-checkbox"
        :checked="runUntaggedSelectorDefaultSelection"
        @input="onUntaggedInput"
      >
        <multiple-choice-selector-item
          value="untagged"
          :title="__('Run untagged jobs')"
          :description="
            s__('Runners|Use the runner for jobs without tags in addition to tagged jobs.')
          "
        />
      </multiple-choice-selector>
    </template>
    <template #next>
      <gl-button category="primary" variant="confirm" @click="onNext">
        {{ __('Next step') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
