<script>
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import StatusIcon from '../mr_widget_status_icon.vue';

const message = s__(
  "mrWidget|%{boldStart}Merge blocked:%{boldEnd} pipeline must succeed. It's waiting for a manual action to continue.",
);

export default {
  name: 'MRWidgetPipelineBlocked',
  message,
  components: {
    BoldText,
    StatusIcon,
  },
  mixins: [glFeatureFlagMixin()],
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon status="failed" />
    <div class="media-body space-children">
      <bold-text :message="$options.message" />
    </div>
  </div>
</template>
