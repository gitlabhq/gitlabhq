<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  inject: {
    svgPath: {
      default: '',
    },
    docsLink: {
      default: '',
    },
    primaryButtonPath: {
      default: '',
    },
  },
};
</script>
<template>
  <gl-empty-state
    class="js-empty-state"
    :title="__('Activate user activity analysis')"
    :svg-path="svgPath"
    :primary-button-text="__('Turn on usage ping')"
    :primary-button-link="primaryButtonPath"
  >
    <template #description>
      <gl-sprintf
        :message="
          __(
            'Turn on %{strongStart}usage ping%{strongEnd} to activate analysis of user activity, known as %{docLinkStart}Cohorts%{docLinkEnd}.',
          )
        "
      >
        <template #docLink="{content}">
          <gl-link :href="docsLink" target="_blank">{{ content }}</gl-link>
        </template>
        <template #strong="{ content }"
          ><strong>{{ content }}</strong></template
        >
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
