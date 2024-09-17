<script>
import { GlLink, GlPopover, GlOutsideDirective as Outside, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { VALIDATE_TAB_FEEDBACK_URL } from '../../constants';

export const i18n = {
  feedbackLink: __('Provide Feedback'),
  popoverContent: s__(
    'PipelineEditor|Pipeline behavior will be simulated including the %{codeStart}rules%{codeEnd} %{codeStart}only%{codeEnd} %{codeStart}except%{codeEnd} and %{codeStart}needs%{codeEnd} job dependencies. %{linkStart}Learn more%{linkEnd}',
  ),
  title: s__('PipelineEditor|Validate pipeline under simulated conditions'),
};

export default {
  name: 'ValidatePipelinePopover',
  directives: { Outside },
  components: {
    GlLink,
    GlPopover,
    GlSprintf,
  },
  inject: ['simulatePipelineHelpPagePath'],
  data() {
    return {
      showPopover: false,
    };
  },
  methods: {
    dismiss() {
      this.showPopover = false;
    },
  },
  i18n,
  VALIDATE_TAB_FEEDBACK_URL,
};
</script>

<template>
  <gl-popover
    :show.sync="showPopover"
    target="validate-pipeline-help"
    triggers="hover focus"
    placement="top"
  >
    <p class="gl-my-3 gl-font-bold">{{ $options.i18n.title }}</p>
    <p>
      <gl-sprintf :message="$options.i18n.popoverContent">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
        <template #link="{ content }">
          <gl-link
            class="gl-text-sm"
            target="_blank"
            :href="simulatePipelineHelpPagePath"
            data-testid="help-link"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </p>
    <p class="gl-mb-3 gl-text-right">
      <gl-link
        class="gl-text-sm"
        target="_blank"
        :href="$options.VALIDATE_TAB_FEEDBACK_URL"
        data-testid="feedback-link"
        >{{ $options.i18n.feedbackLink }}</gl-link
      >
    </p>
  </gl-popover>
</template>
