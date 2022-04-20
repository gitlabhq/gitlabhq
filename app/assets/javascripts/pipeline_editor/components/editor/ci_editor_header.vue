<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { pipelineEditorTrackingOptions, TEMPLATE_REPOSITORY_URL } from '../../constants';

export default {
  i18n: {
    browseTemplates: __('Browse templates'),
    help: __('Help'),
  },
  TEMPLATE_REPOSITORY_URL,
  components: {
    GlButton,
  },
  mixins: [Tracking.mixin()],
  props: {
    showDrawer: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    toggleDrawer() {
      this.$emit(this.showDrawer ? 'close-drawer' : 'open-drawer');
    },
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
  </div>
</template>
