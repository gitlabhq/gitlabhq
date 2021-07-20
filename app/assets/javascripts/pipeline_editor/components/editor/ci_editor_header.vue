<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { pipelineEditorTrackingOptions, TEMPLATE_REPOSITORY_URL } from '../../constants';

export default {
  i18n: {
    browseTemplates: __('Browse templates'),
  },
  TEMPLATE_REPOSITORY_URL,
  components: {
    GlButton,
  },
  mixins: [Tracking.mixin()],
  methods: {
    trackTemplateBrowsing() {
      const { label, actions } = pipelineEditorTrackingOptions;

      this.track(actions.browse_templates, { label });
    },
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-p-3 gl-border-solid gl-border-gray-100 gl-border-1">
    <gl-button
      :href="$options.TEMPLATE_REPOSITORY_URL"
      size="small"
      icon="external-link"
      target="_blank"
      @click="trackTemplateBrowsing"
    >
      {{ $options.i18n.browseTemplates }}
    </gl-button>
  </div>
</template>
