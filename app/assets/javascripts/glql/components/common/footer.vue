<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'GlqlFooter',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  docsPath: `${helpPagePath('user/glql/_index')}#glql-views`,
};
</script>
<template>
  <div class="gl-flex gl-items-center gl-gap-1 gl-text-sm gl-text-subtle" data-testid="footer">
    <gl-icon class="gl-mb-1 gl-mr-1" :size="12" name="tanuki" />
    <gl-sprintf :message="__('%{linkStart}View%{linkEnd} powered by GLQL')">
      <template #link="{ content }">
        <gl-link :href="$options.docsPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
