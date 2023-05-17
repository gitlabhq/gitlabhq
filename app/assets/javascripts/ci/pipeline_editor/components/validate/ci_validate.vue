<script>
import {
  GlAlert,
  GlButton,
  GlDisclosureDropdown,
  GlIcon,
  GlLoadingIcon,
  GlLink,
  GlTooltip,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { pipelineEditorTrackingOptions } from '../../constants';
import ValidatePipelinePopover from '../popovers/validate_pipeline_popover.vue';
import CiLintResults from '../lint/ci_lint_results.vue';
import getBlobContent from '../../graphql/queries/blob_content.query.graphql';
import getCurrentBranch from '../../graphql/queries/client/current_branch.query.graphql';
import lintCiMutation from '../../graphql/mutations/client/lint_ci.mutation.graphql';

export const i18n = {
  alertDesc: s__(
    'PipelineEditor|Simulated a %{codeStart}git push%{codeEnd} event for a default branch. %{codeStart}Rules%{codeEnd}, %{codeStart}only%{codeEnd}, %{codeStart}except%{codeEnd}, and %{codeStart}needs%{codeEnd} job dependencies logic have been evaluated. %{linkStart}Learn more%{linkEnd}',
  ),
  cancelBtn: __('Cancel'),
  contentChange: s__(
    'PipelineEditor|Configuration content has changed. Re-run validation for updated results.',
  ),
  cta: s__('PipelineEditor|Validate pipeline'),
  ctaDisabledTooltip: s__('PipelineEditor|Waiting for CI content to load...'),
  errorAlertTitle: s__('PipelineEditor|Pipeline simulation completed with errors'),
  help: __('Help'),
  loading: s__('PipelineEditor|Validating pipeline... It can take up to a minute.'),
  pipelineSource: s__('PipelineEditor|Pipeline Source'),
  pipelineSourceDefault: s__('PipelineEditor|Git push event to the default branch'),
  pipelineSourceTooltip: s__('PipelineEditor|Other pipeline sources are not available yet.'),
  title: s__('PipelineEditor|Validate pipeline under selected conditions'),
  contentNote: s__(
    'PipelineEditor|Current content in the Edit tab will be used for the simulation.',
  ),
  simulationNote: s__(
    'PipelineEditor|Pipeline behavior will be simulated including the %{codeStart}rules%{codeEnd} %{codeStart}only%{codeEnd} %{codeStart}except%{codeEnd} and %{codeStart}needs%{codeEnd} job dependencies.',
  ),
  successAlertTitle: s__('PipelineEditor|Simulation completed successfully'),
};

export const VALIDATE_TAB_INIT = 'VALIDATE_TAB_INIT';
export const VALIDATE_TAB_RESULTS = 'VALIDATE_TAB_RESULTS';
export const VALIDATE_TAB_LOADING = 'VALIDATE_TAB_LOADING';
const BASE_CLASSES = [
  'gl-display-flex',
  'gl-flex-direction-column',
  'gl-align-items-center',
  'gl-mt-11',
];

export default {
  name: 'CiValidateTab',
  components: {
    CiLintResults,
    GlAlert,
    GlButton,
    GlDisclosureDropdown,
    GlIcon,
    GlLoadingIcon,
    GlLink,
    GlSprintf,
    GlTooltip,
    ValidatePipelinePopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['ciConfigPath', 'ciLintPath', 'projectFullPath', 'validateTabIllustrationPath'],
  props: {
    ciFileContent: {
      type: String,
      required: true,
    },
  },
  apollo: {
    initialBlobContent: {
      query: getBlobContent,
      variables() {
        return {
          projectPath: this.projectFullPath,
          path: this.ciConfigPath,
          ref: this.currentBranch,
        };
      },
      update(data) {
        return data?.project?.repository?.blobs?.nodes[0]?.rawBlob;
      },
    },
    currentBranch: {
      query: getCurrentBranch,
      update(data) {
        return data.workBranches?.current?.name;
      },
    },
  },
  data() {
    return {
      yaml: this.ciFileContent,
      state: VALIDATE_TAB_INIT,
      errors: [],
      hasCiContentChanged: false,
      isValid: false,
      jobs: [],
      warnings: [],
    };
  },
  computed: {
    canResimulatePipeline() {
      return this.hasSimulationResults && this.hasCiContentChanged;
    },
    isInitialCiContentLoading() {
      return this.$apollo.queries.initialBlobContent.loading;
    },
    isInitState() {
      return this.state === VALIDATE_TAB_INIT;
    },
    isSimulationLoading() {
      return this.state === VALIDATE_TAB_LOADING;
    },
    hasSimulationResults() {
      return this.state === VALIDATE_TAB_RESULTS;
    },
    resultStatus() {
      return {
        title: this.isValid ? i18n.successAlertTitle : i18n.errorAlertTitle,
        variant: this.isValid ? 'success' : 'danger',
      };
    },
    trackingAction() {
      const { actions } = pipelineEditorTrackingOptions;
      return this.canResimulatePipeline ? actions.resimulatePipeline : actions.simulatePipeline;
    },
  },
  watch: {
    ciFileContent(value) {
      this.yaml = value;
      this.hasCiContentChanged = true;
    },
  },
  methods: {
    cancelSimulation() {
      this.state = VALIDATE_TAB_INIT;
    },
    trackSimulation() {
      const { label } = pipelineEditorTrackingOptions;
      this.track(this.trackingAction, { label });
    },
    async validateYaml() {
      this.trackSimulation();
      this.state = VALIDATE_TAB_LOADING;

      try {
        const {
          data: {
            lintCI: { errors, jobs, valid, warnings },
          },
        } = await this.$apollo.mutate({
          mutation: lintCiMutation,
          variables: {
            dry: true,
            content: this.yaml,
            endpoint: this.ciLintPath,
          },
        });

        // only save the result if the user did not cancel the simulation
        if (this.state === VALIDATE_TAB_LOADING) {
          this.errors = errors;
          this.jobs = jobs;
          this.warnings = warnings;
          this.isValid = valid;
          this.state = VALIDATE_TAB_RESULTS;
          this.hasCiContentChanged = false;
        }
      } catch (error) {
        this.cancelSimulation();
      }
    },
  },
  i18n,
  BASE_CLASSES,
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-mt-3">
      <div>
        <label>{{ $options.i18n.pipelineSource }}</label>
        <gl-disclosure-dropdown
          v-gl-tooltip.hover
          class="gl-ml-3"
          :title="$options.i18n.pipelineSourceTooltip"
          :toggle-text="$options.i18n.pipelineSourceDefault"
          disabled
          data-testid="pipeline-source"
        />
        <validate-pipeline-popover />
        <gl-icon
          id="validate-pipeline-help"
          name="question-o"
          class="gl-ml-1 gl-fill-blue-500"
          category="secondary"
          variant="confirm"
          :aria-label="$options.i18n.help"
        />
      </div>
      <div v-if="canResimulatePipeline">
        <span class="gl-text-gray-400" data-testid="content-status">
          {{ $options.i18n.contentChange }}
        </span>
        <gl-button
          variant="confirm"
          class="gl-ml-2 gl-mb-2"
          data-testid="resimulate-pipeline-button"
          @click="validateYaml"
        >
          {{ $options.i18n.cta }}
        </gl-button>
      </div>
    </div>
    <div v-if="isInitState" :class="$options.BASE_CLASSES">
      <img :src="validateTabIllustrationPath" />
      <h1 class="gl-font-size-h1 gl-mb-6">{{ $options.i18n.title }}</h1>
      <ul>
        <li class="gl-mb-3">{{ $options.i18n.contentNote }}</li>
        <li class="gl-mb-3">
          <gl-sprintf :message="$options.i18n.simulationNote">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </li>
      </ul>
      <div ref="simulatePipelineButton">
        <gl-button
          ref="simulatePipelineButton"
          variant="confirm"
          class="gl-mt-3"
          :disabled="isInitialCiContentLoading"
          data-testid="simulate-pipeline-button"
          data-qa-selector="simulate_pipeline_button"
          @click="validateYaml"
        >
          {{ $options.i18n.cta }}
        </gl-button>
      </div>
      <gl-tooltip
        v-if="isInitialCiContentLoading"
        :target="() => $refs.simulatePipelineButton"
        :title="$options.i18n.ctaDisabledTooltip"
        data-testid="cta-tooltip"
      />
    </div>
    <div v-else-if="isSimulationLoading" :class="$options.BASE_CLASSES">
      <gl-loading-icon size="lg" class="gl-m-3" />
      <h1 class="gl-font-size-h1 gl-mb-6">{{ $options.i18n.loading }}</h1>
      <div>
        <gl-button class="gl-mt-3" data-testid="cancel-simulation" @click="cancelSimulation">
          {{ $options.i18n.cancelBtn }}
        </gl-button>
        <gl-button class="gl-mt-3" loading data-testid="simulate-pipeline-button">
          {{ $options.i18n.cta }}
        </gl-button>
      </div>
    </div>
    <div v-else-if="hasSimulationResults" class="gl-mt-5">
      <gl-alert
        class="gl-mb-5"
        :dismissible="false"
        :title="resultStatus.title"
        :variant="resultStatus.variant"
      >
        <gl-sprintf :message="$options.i18n.alertDesc">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
          <template #link="{ content }">
            <gl-link target="_blank" href="#">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
      <ci-lint-results
        dry-run
        hide-alert
        :is-valid="isValid"
        :jobs="jobs"
        :errors="errors"
        :warnings="warnings"
      />
    </div>
  </div>
</template>
