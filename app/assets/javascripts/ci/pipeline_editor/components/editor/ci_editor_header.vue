<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { pipelineEditorTrackingOptions, TEMPLATE_REPOSITORY_URL } from '../../constants';

export default {
  i18n: {
    browseTemplates: __('Browse templates'),
    help: __('Help'),
    jobAssistant: s__('JobAssistant|Job assistant'),
    aiAssistant: s__('PipelinesAiAssistant|Ai assistant'),
  },
  TEMPLATE_REPOSITORY_URL,
  components: {
    GlButton,
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin()],
  props: {
    showDrawer: {
      type: Boolean,
      required: true,
    },
    showJobAssistantDrawer: {
      type: Boolean,
      required: true,
    },
    showAiAssistantDrawer: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    toggleDrawer() {
      if (this.showDrawer) {
        this.$emit('close-drawer');
      } else {
        this.$emit('open-drawer');
        this.trackHelpDrawerClick();
      }
    },
    toggleJobAssistantDrawer() {
      this.$emit(
        this.showJobAssistantDrawer ? 'close-job-assistant-drawer' : 'open-job-assistant-drawer',
      );
    },
    toggleAiAssistantDrawer() {
      this.$emit(
        this.showAiAssistantDrawer ? 'close-ai-assistant-drawer' : 'open-ai-assistant-drawer',
      );
    },
    trackHelpDrawerClick() {
      const { label, actions } = pipelineEditorTrackingOptions;
      this.track(actions.openHelpDrawer, { label });
    },
    trackTemplateBrowsing() {
      const { label, actions } = pipelineEditorTrackingOptions;

      this.track(actions.browseTemplates, { label });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-p-3 gl-gap-3 gl-border-solid gl-border-gray-100 gl-border-1">
    <gl-button
      :href="$options.TEMPLATE_REPOSITORY_URL"
      size="small"
      icon="external-link"
      target="_blank"
      data-testid="template-repo-link"
      data-qa-selector="template_repo_link"
      @click="trackTemplateBrowsing"
    >
      {{ $options.i18n.browseTemplates }}
    </gl-button>
    <gl-button
      icon="information-o"
      size="small"
      data-testid="drawer-toggle"
      data-qa-selector="drawer_toggle"
      @click="toggleDrawer"
    >
      {{ $options.i18n.help }}
    </gl-button>
    <gl-button
      v-if="glFeatures.ciJobAssistantDrawer"
      icon="bulb"
      size="small"
      data-testid="job-assistant-drawer-toggle"
      data-qa-selector="job_assistant_drawer_toggle"
      @click="toggleJobAssistantDrawer"
    >
      {{ $options.i18n.jobAssistant }}
    </gl-button>
    <gl-button
      v-if="glFeatures.aiCiConfigGenerator"
      icon="bulb"
      size="small"
      data-testid="ai-assistant-drawer-toggle"
      data-qa-selector="ai_assistant_drawer_toggle"
      @click="toggleAiAssistantDrawer"
    >
      {{ $options.i18n.aiAssistant }}
    </gl-button>
  </div>
</template>
