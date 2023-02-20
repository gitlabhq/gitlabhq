<script>
import { s__ } from '~/locale';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import StatusIcon from '../mr_widget_status_icon.vue';

const message = s__(
  'mrWidget|%{boldStart}Ready to be merged automatically.%{boldEnd} Ask someone with write access to this repository to merge this request.',
);

export default {
  name: 'MRWidgetNotAllowed',
  message,
  components: {
    BoldText,
    StatusIcon,
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon status="success" />
    <div class="media-body space-children">
      <bold-text :message="$options.message" />
    </div>
  </div>
</template>
