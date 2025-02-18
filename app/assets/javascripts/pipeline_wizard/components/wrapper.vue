<script>
import { GlProgressBar } from '@gitlab/ui';
import { Document } from 'yaml';
import { uniqueId } from 'lodash';
import { merge } from '~/lib/utils/yaml';
import { __ } from '~/locale';
import { isValidStepSeq } from '~/pipeline_wizard/validators';
import Tracking from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import YamlEditor from './editor.vue';
import WizardStep from './step.vue';
import CommitStep from './commit.vue';

export const i18n = {
  stepNofN: __('Step %{currentStep} of %{stepCount}'),
  draft: __('Draft: %{filename}'),
  overlayMessage: __(`Enter values to populate the .gitlab-ci.yml configuration file.`),
};

const trackingMixin = Tracking.mixin();

export default {
  name: 'PipelineWizardWrapper',
  i18n,
  components: {
    GlProgressBar,
    YamlEditor,
    WizardStep,
    CommitStep,
  },
  mixins: [trackingMixin, glFeatureFlagsMixin()],
  props: {
    steps: {
      type: Object,
      required: true,
      validator: isValidStepSeq,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    filename: {
      type: String,
      required: true,
    },
    templateId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      highlightPath: null,
      currentStepIndex: 0,
      // TODO: In order to support updating existing pipelines, the below
      // should contain a parsed version of an existing .gitlab-ci.yml.
      // See https://gitlab.com/gitlab-org/gitlab/-/issues/355306
      compiled: new Document({}),
      showPlaceholder: true,
      pipelineBlob: null,
      placeholder: this.getPlaceholder(),
    };
  },
  computed: {
    currentStep() {
      return this.currentStepIndex + 1;
    },
    stepCount() {
      return this.steps.items.length + 1;
    },
    progress() {
      return Math.ceil((this.currentStep / (this.stepCount + 1)) * 100);
    },
    isLastStep() {
      return this.currentStep === this.stepCount;
    },
    stepList() {
      return this.steps.items.map((_, i) => ({
        id: uniqueId(),
        inputs: this.steps.get(i).get('inputs').toJSON(),
        template: this.steps.get(i).get('template', true),
      }));
    },
    tracking() {
      return {
        category: `pipeline_wizard:${this.templateId}`,
      };
    },
    trackingExtraData() {
      return {
        features: this.glFeatures,
      };
    },
  },
  watch: {
    isLastStep(value) {
      if (value) this.resetHighlight();
    },
  },
  methods: {
    resetHighlight() {
      this.highlightPath = null;
    },
    onUpdate() {
      this.showPlaceholder = false;
    },
    onEditorUpdate(blob) {
      // TODO: In a later iteration, we could add a loopback allowing for
      //  changes from the editor to flow back into the model
      // see https://gitlab.com/gitlab-org/gitlab/-/issues/355312
      this.pipelineBlob = blob;
    },
    getPlaceholder() {
      const doc = new Document({});
      this.steps.items.forEach((tpl) => {
        merge(doc, tpl.get('template').clone());
      });
      return doc;
    },
    onBack() {
      this.currentStepIndex -= 1;
      this.track('click_button', {
        property: 'back',
        label: 'pipeline_wizard_navigation',
        extra: {
          fromStep: this.currentStepIndex + 1,
          toStep: this.currentStepIndex,
          ...this.trackingExtraData,
        },
      });
    },
    onNext() {
      this.currentStepIndex += 1;
      this.track('click_button', {
        property: 'next',
        label: 'pipeline_wizard_navigation',
        extra: {
          fromStep: this.currentStepIndex - 1,
          toStep: this.currentStepIndex,
          ...this.trackingExtraData,
        },
      });
    },
    onDone() {
      this.$emit('done');
      this.track('click_button', {
        label: 'pipeline_wizard_commit',
        property: 'commit',
        extra: this.trackingExtraData,
      });
    },
    onEditorTouched() {
      this.track('edit', {
        label: 'pipeline_wizard_editor_interaction',
        extra: {
          currentStep: this.currentStepIndex,
          ...this.trackingExtraData,
        },
      });
    },
  },
};
</script>

<template>
  <div class="row gl-mt-8">
    <main class="col-md-6 gl-pr-8">
      <header class="gl-mb-5">
        <h2 class="gl-mt-0" data-testid="step-count">
          {{ sprintf($options.i18n.stepNofN, { currentStep, stepCount }) }}
        </h2>
        <gl-progress-bar :value="progress" />
      </header>
      <section class="gl-mb-4">
        <commit-step
          v-show="isLastStep"
          data-testid="step"
          :default-branch="defaultBranch"
          :file-content="pipelineBlob"
          :filename="filename"
          :project-path="projectPath"
          @back="onBack"
          @done="onDone"
        />
        <wizard-step
          v-for="(step, i) in stepList"
          v-show="i === currentStepIndex"
          :key="step.id"
          data-testid="step"
          :compiled.sync="compiled"
          :has-next-step="i < steps.items.length"
          :has-previous-step="i > 0"
          :highlight.sync="highlightPath"
          :inputs="step.inputs"
          :template="step.template"
          @back="onBack"
          @next="onNext"
          @update:compiled="onUpdate"
        />
      </section>
    </main>
    <aside class="col-md-6 gl-pt-3">
      <div class="gl-rounded-base gl-border-1 gl-border-solid gl-border-default gl-bg-subtle">
        <h6 class="gl-p-2 gl-px-4 gl-text-subtle" data-testid="editor-header">
          {{ sprintf($options.i18n.draft, { filename }) }}
        </h6>
        <div class="gl-relative gl-overflow-hidden">
          <yaml-editor
            :aria-hidden="showPlaceholder"
            :doc="showPlaceholder ? placeholder : compiled"
            :filename="filename"
            :highlight="highlightPath"
            class="gl-w-full"
            @update:yaml="onEditorUpdate"
            @touch.once="onEditorTouched"
          />
          <div
            v-if="showPlaceholder"
            class="gl-absolute gl-bottom-0 gl-left-0 gl-right-0 gl-top-0 gl-backdrop-blur-sm"
            data-testid="placeholder-overlay"
          >
            <div
              class="gl-absolute gl-bottom-0 gl-left-0 gl-right-0 gl-top-0 gl-z-2 gl-bg-overlay"
            ></div>
            <div class="gl-relative gl-z-3 gl-flex gl-h-full gl-items-center gl-justify-center">
              <div class="gl-max-w-34 gl-rounded-base gl-bg-overlap gl-p-6">
                <h4 data-testid="filename" class="gl-heading-4">{{ filename }}</h4>
                <p data-testid="description" class="gl-mb-0 gl-text-subtle">
                  {{ $options.i18n.overlayMessage }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </aside>
  </div>
</template>
