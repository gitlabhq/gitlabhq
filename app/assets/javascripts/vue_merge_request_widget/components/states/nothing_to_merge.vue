<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { STATUS_EMPTY } from '~/issues/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetNothingToMerge',
  components: {
    GlSprintf,
    GlLink,
    StatusIcon,
  },
  computed: {
    statusEmpty() {
      return STATUS_EMPTY;
    },
  },
  ciHelpPage: helpPagePath('ci/quick_start/index.html'),
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon :status="statusEmpty" />
    <div>
      <p class="media-body gl-mt-1 gl-mb-1 gl-font-weight-bold gl-text-gray-900!">
        {{ s__('mrWidgetNothingToMerge|Merge request contains no changes') }}
      </p>
      <p class="gl-m-0! gl-text-secondary" data-testid="nothing-to-merge-body">
        <gl-sprintf
          :message="
            s__(
              'mrWidgetNothingToMerge|Use merge requests to propose changes to your project and discuss them with your team. To make changes, use the %{boldStart}Code%{boldEnd} dropdown list above, then test them with %{linkStart}CI/CD%{linkEnd} before merging.',
            )
          "
        >
          <template #bold="{ content }">
            <b>{{ content }}</b>
          </template>
          <template #link="{ content }">
            <gl-link :href="$options.ciHelpPage" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
  </div>
</template>
