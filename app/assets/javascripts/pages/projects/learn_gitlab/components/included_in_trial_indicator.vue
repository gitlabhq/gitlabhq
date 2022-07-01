<script>
import { s__ } from '~/locale';

export default {
  name: 'IncludedInTrialIndicator',
  i18n: {
    trialOnly: s__('LearnGitlab|- Included in trial'),
  },
};
</script>
<template>
  <span class="gl-font-style-italic gl-text-gray-500" data-testid="trial-only">
    {{ $options.i18n.trialOnly }}
  </span>
</template>
