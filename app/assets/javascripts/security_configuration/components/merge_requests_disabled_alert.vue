<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'MergeRequestsDisabledAlert',
  components: {
    GlAlert,
    GlSprintf,
  },
  i18n: {
    title: s__('SecurityConfiguration|Merge requests are disabled'),
    body: s__(
      'SecurityConfiguration|Security configuration uses merge requests to change the `.gitlab-ci.yml` file. Enable merge requests for this project if you are a maintainer, or ask a maintainer to do this for you.',
    ),
    instructions: s__(
      'SecurityConfiguration|Enable merge requests in Project Settings %{gt} General %{gt} Visibility, project features, permissions.',
    ),
  },
};
</script>

<template>
  <gl-alert variant="warning" :dismissible="false">
    <strong>{{ $options.i18n.title }}</strong>
    <p class="gl-mb-0 gl-mt-3">
      {{ $options.i18n.body }}
    </p>
    <p class="gl-mb-0 gl-mt-3">
      <gl-sprintf :message="$options.i18n.instructions">
        <template #gt>&gt;</template>
      </gl-sprintf>
    </p>
  </gl-alert>
</template>
