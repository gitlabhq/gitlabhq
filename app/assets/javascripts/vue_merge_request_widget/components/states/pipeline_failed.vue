<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'PipelineFailed',
  components: {
    GlLink,
    GlSprintf,
    statusIcon,
  },
  computed: {
    troubleshootingDocsPath() {
      return helpPagePath('ci/troubleshooting', { anchor: 'merge-request-status-messages' });
    },
  },
  i18n: {
    failedMessage: s__(
      `mrWidget|The pipeline for this merge request did not complete. Push a new commit to fix the failure, or check the %{linkStart}troubleshooting documentation%{linkEnd} to see other possible actions.`,
    ),
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />
    <div class="media-body space-children">
      <span class="bold">
        <gl-sprintf :message="$options.i18n.failedMessage">
          <template #link="{ content }">
            <gl-link :href="troubleshootingDocsPath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </span>
    </div>
  </div>
</template>
