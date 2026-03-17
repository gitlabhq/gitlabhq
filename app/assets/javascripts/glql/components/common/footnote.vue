<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'GlqlFootnote',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
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
  </div>
</template>
