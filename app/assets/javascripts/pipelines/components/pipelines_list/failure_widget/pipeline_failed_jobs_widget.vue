<script>
import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
  },
  props: {
    pipelinePath: {
      required: true,
      type: String,
    },
  },

  i18n: {
    additionalInfoPopover: s__(
      'Pipelines|You will see a maximum of 100 jobs in this list. To view all failed jobs, %{linkStart}go to the details page%{linkEnd} of this pipeline.',
    ),
    additionalInfoTitle: __('Limitation on this view'),
    showFailedJobs: __('Show failed jobs'),
  },
};
</script>
<template>
  <div class="gl-border-none!">
    <gl-icon name="chevron-right" />
    {{ $options.i18n.showFailedJobs }}
    <gl-icon id="target" name="information-o" />
    <gl-popover target="target" placement="top">
      <template #title> {{ $options.i18n.additionalInfoTitle }} </template>
      <slot>
        <gl-sprintf :message="$options.i18n.additionalInfoPopover">
          <template #link="{ content }">
            <gl-link class="gl-font-sm" :href="pipelinePath"> {{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </slot>
    </gl-popover>
  </div>
</template>
