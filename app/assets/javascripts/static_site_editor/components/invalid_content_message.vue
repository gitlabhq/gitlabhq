<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
};
</script>

<template>
  <div>
    <h3>{{ s__('StaticSiteEditor|Incompatible file content') }}</h3>
    <p>
      {{
        s__(
          'StaticSiteEditor|The Static Site Editor is currently configured to only edit Markdown content on pages generated from Middleman. Visit the documentation to learn more about configuring your site to use the Static Site Editor.',
        )
      }}
    </p>
    <div>
      <gl-button
        ref="documentationButton"
        href="https://gitlab.com/gitlab-org/project-templates/static-site-editor-middleman"
        >{{ s__('StaticSiteEditor|View documentation') }}</gl-button
      >
    </div>
  </div>
</template>
