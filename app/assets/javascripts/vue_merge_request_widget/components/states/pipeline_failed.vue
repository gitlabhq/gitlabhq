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
      `mrWidget|Merge blocked: pipeline must succeed. Push a commit that fixes the failure, or %{linkStart}learn about other solutions.%{linkEnd}`,
    ),
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />
    <div class="media-body space-children">
      <span class="gl-ml-0! gl-text-body! bold">
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
