<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'PipelineFailed',
  components: {
    BoldText,
    GlLink,
    GlSprintf,
    StatusIcon,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  computed: {
    troubleshootingDocsPath() {
      return helpPagePath('ci/troubleshooting', { anchor: 'merge-request-status-messages' });
    },
  },
  i18n: {
    failedMessage: s__(
      `mrWidget|%{boldStart}Merge blocked:%{boldEnd} pipeline must succeed. Push a commit that fixes the failure or %{linkStart}learn about other solutions.%{linkEnd}`,
    ),
    blockedMessage: s__(
      "mrWidget|%{boldStart}Merge blocked:%{boldEnd} pipeline must succeed. It's waiting for a manual action to continue.",
    ),
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon status="failed" />
    <div class="media-body space-children">
      <span>
        <bold-text v-if="mr.isPipelineBlocked" :message="$options.i18n.blockedMessage" />
        <gl-sprintf v-else :message="$options.i18n.failedMessage">
          <template #link="{ content }">
            <gl-link :href="troubleshootingDocsPath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
          <template #bold="{ content }">
            <span class="gl-font-weight-bold">{{ content }}</span>
          </template>
        </gl-sprintf>
      </span>
    </div>
  </div>
</template>
