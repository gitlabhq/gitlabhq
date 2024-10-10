<script>
import SCHEDULE_MD_SVG_URL from '@gitlab/svgs/dist/illustrations/schedule-md.svg?url';
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  i18n: {
    pipelineSchedules: s__('PipelineSchedules|Pipeline schedules'),
    description: s__(
      'PipelineSchedules|A scheduled pipeline starts automatically at regular intervals, like daily or weekly. The pipeline: ',
    ),
    learnMore: s__(
      'PipelineSchedules|Learn more in the %{linkStart}scheduled pipelines documentation.%{linkEnd}',
    ),
    listElements: [
      s__('PipelineSchedules|Runs for a specific branch or tag.'),
      s__('PipelineSchedules|Can have custom CI/CD variables.'),
      s__('PipelineSchedules|Runs with the same project permissions as the schedule owner.'),
    ],
    createNew: s__('PipelineSchedules|Create a new pipeline schedule'),
  },
  SCHEDULE_MD_SVG_URL,
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  inject: {
    newSchedulePath: {
      default: '',
    },
  },
  computed: {
    schedulesHelpPath() {
      return helpPagePath('ci/pipelines/schedules');
    },
  },
};
</script>
<template>
  <gl-empty-state
    :title="$options.i18n.pipelineSchedules"
    :svg-path="$options.SCHEDULE_MD_SVG_URL"
    :svg-height="150"
    :primary-button-text="$options.i18n.createNew"
    :primary-button-link="newSchedulePath"
  >
    <template #description>
      <p class="gl-mb-0">{{ $options.i18n.description }}</p>
      <ul class="gl-list-inside" data-testid="pipeline-schedules-characteristics">
        <li v-for="(el, index) in $options.i18n.listElements" :key="index">{{ el }}</li>
      </ul>
      <p>
        <gl-sprintf :message="$options.i18n.learnMore">
          <template #link="{ content }">
            <gl-link :href="schedulesHelpPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-empty-state>
</template>
