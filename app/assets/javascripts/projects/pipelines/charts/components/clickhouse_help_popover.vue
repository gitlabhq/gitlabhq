<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'ClickHouseHelpPopover',
  components: {
    GlLink,
    GlSprintf,
    HelpPopover,
  },
  mixins: [glFeatureFlagsMixin()],
  clickHouseForAnalyticsHelpPagePath: helpPagePath('administration/analytics'),
};
</script>
<template>
  <help-popover v-if="glFeatures.ciImprovedProjectPipelineAnalytics">
    <template #title>
      {{ s__('PipelineCharts|Try ClickHouse for advanced analytics') }}
    </template>
    <gl-sprintf
      :message="
        s__(
          'PipelineCharts|ClickHouse can provide a more comprehensive pipelines analytics for your project. %{linkStart}See how to enable Clickhouse for analytics%{linkEnd}.',
        )
      "
    >
      <template #link="{ content }">
        <gl-link :href="$options.clickHouseForAnalyticsHelpPagePath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </help-popover>
</template>
