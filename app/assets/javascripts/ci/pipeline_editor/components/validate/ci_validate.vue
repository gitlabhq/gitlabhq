<script>
import {
  GlAlert,
  GlButton,
  GlDisclosureDropdown,
  GlLoadingIcon,
  GlLink,
  GlTooltip,
  GlTooltipDirective,
  GlSprintf,
  GlEmptyState,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
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
  lint: s__('PipelineEditor|Lint CI/CD sample'),
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
const BASE_CLASSES = ['gl-flex', 'gl-flex-col', 'gl-items-center', 'gl-mt-11'];

export default {
  name: 'CiValidateTab',
  components: {
    CiLintResults,
    GlAlert,
    GlButton,
    GlDisclosureDropdown,
    GlLoadingIcon,
    GlLink,
    GlSprintf,
    GlTooltip,
    GlEmptyState,
    ValidatePipelinePopover,
    HelpIcon,
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
  lintHref: helpPagePath('ci/yaml/lint.md'),
};
</script>

<template>
  <div>
    <div class="gl-mt-3 gl-flex gl-justify-between">
      <div>
        <label>{{ $options.i18n.pipelineSource }}</label>
        <gl-disclosure-dropdown
          v-gl-tooltip.hover
          class="gl-ml-3"
          :title="$options.i18n.pipelineSourceTooltip"
          :toggle-text="$options.i18n.pipelineSourceDefault"
          disabled
        />
        <validate-pipeline-popover />
        <help-icon id="validate-pipeline-help" class="gl-ml-1" :aria-label="$options.i18n.help" />
      </div>
      <div v-if="canResimulatePipeline">
        <span class="gl-text-subtle" data-testid="content-status">
          {{ $options.i18n.contentChange }}
        </span>
        <gl-button
          variant="confirm"
          class="gl-mb-2 gl-ml-2"
          data-testid="resimulate-pipeline-button"
          @click="validateYaml"
        >
          {{ $options.i18n.cta }}
        </gl-button>
      </div>
    </div>
    <gl-empty-state
      v-if="isInitState"
      :svg-path="validateTabIllustrationPath"
      :title="$options.i18n.title"
    >
      <template #description>
        <p>{{ $options.i18n.contentNote }}</p>
        <p>
          <gl-sprintf :message="$options.i18n.simulationNote">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </p>
      </template>
      <template #actions>
        <div ref="simulatePipelineButton">
          <gl-button
            ref="simulatePipelineButton"
            variant="confirm"
            class="gl-mt-3"
            :disabled="isInitialCiContentLoading"
            data-testid="simulate-pipeline-button"
            @click="validateYaml"
          >
            {{ $options.i18n.cta }}
          </gl-button>
        </div>
        <gl-button
          v-if="ciLintPath"
          class="gl-ml-3 gl-mt-3"
          :href="ciLintPath"
          data-testid="lint-button"
        >
          {{ $options.i18n.lint }}
        </gl-button>
        <gl-tooltip
          v-if="isInitialCiContentLoading"
          :target="() => $refs.simulatePipelineButton"
          :title="$options.i18n.ctaDisabledTooltip"
          data-testid="cta-tooltip"
        />
      </template>
    </gl-empty-state>
    <div v-else-if="isSimulationLoading" :class="$options.BASE_CLASSES">
      <gl-loading-icon size="lg" class="gl-m-3" />
      <h1 class="gl-mb-6 gl-text-size-h1">{{ $options.i18n.loading }}</h1>
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
            <gl-link target="_blank" :href="$options.lintHref">{{ content }}</gl-link>
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
