<script>
import { GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlSprintf,
  },
  i18n: {
    title: __('Optimize your workflow with CI/CD Pipelines'),
    body: __(
      'Create a new %{codeStart}.gitlab-ci.yml%{codeEnd} file at the root of the repository to get started.',
    ),
  },
  inject: {
    emptyStateIllustrationPath: {
      default: '',
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-mt-11">
    <img :src="emptyStateIllustrationPath" />
    <h1 class="gl-font-size-h1">{{ $options.i18n.title }}</h1>
    <p>
      <gl-sprintf :message="$options.i18n.body">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
