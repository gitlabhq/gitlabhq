<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';

export default {
  name: 'GoogleCloudLearnMoreLink',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    href: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf
      :message="s__('Runners|Learn more in the %{linkStart}Google Cloud documentation%{linkEnd}.')"
    >
      <template #link="{ content }">
        <gl-link :href="href" target="_blank"
          >{{ content }}<gl-icon name="external-link" :aria-label="__('(external link)')"
        /></gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
