<script>
import { GlIcon, GlLink, GlSprintf, GlExperimentBadge } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { glqlAggregationEnabled, glqlWorkItemsFeatureFlagEnabled } from '../../utils/feature_flags';

export default {
  name: 'GlqlFootnote',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    GlExperimentBadge,
  },
  computed: {
    featureFlagEnabled() {
      return glqlWorkItemsFeatureFlagEnabled() || glqlAggregationEnabled();
    },
  },
  docsPath: `${helpPagePath('user/glql/_index')}#embedded-views`,
};
</script>

<template>
  <div class="gl-mb-5 gl-mt-2 gl-flex gl-items-center gl-gap-1 gl-text-sm gl-text-subtle">
    <gl-icon class="gl-mb-1 gl-mr-1" :size="12" name="tanuki" />
    <gl-sprintf :message="__('%{linkStart}Embedded view%{linkEnd} powered by GLQL')">
      <template #link="{ content }">
        <gl-link
          :href="$options.docsPath"
          target="_blank"
          data-event-tracking="click_glql_info_link"
          >{{ content }}</gl-link
        >
      </template>
    </gl-sprintf>
    <gl-experiment-badge v-if="featureFlagEnabled" type="experiment" class="!gl-mx-2" />
  </div>
</template>
