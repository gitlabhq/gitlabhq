<script>
import { GlButton, GlDropdown, GlIcon, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ValidatePipelinePopover from '../popovers/validate_pipeline_popover.vue';

export const i18n = {
  help: __('Help'),
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
  cta: s__('PipelineEditor|Validate pipeline'),
};

export default {
  name: 'CiValidateTab',
  components: {
    GlButton,
    GlDropdown,
    GlIcon,
    GlSprintf,
    ValidatePipelinePopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['validateTabIllustrationPath'],
  i18n,
};
</script>

<template>
  <div>
    <div class="gl-mt-3">
      <label>{{ $options.i18n.pipelineSource }}</label>
      <gl-dropdown
        v-gl-tooltip.hover
        :title="$options.i18n.pipelineSourceTooltip"
        :text="$options.i18n.pipelineSourceDefault"
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
    <div class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-mt-11">
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
      <gl-button variant="confirm" class="gl-mt-3" data-qa-selector="simulate_pipeline">
        {{ $options.i18n.cta }}
      </gl-button>
    </div>
  </div>
</template>
