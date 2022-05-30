<script>
import { __ } from '~/locale';

export default {
  name: 'BranchRules',
  i18n: { heading: __('Branch') },
};
</script>

<template>
  <div>
    <strong>{{ $options.i18n.heading }}</strong>

    <!-- TODO - List branch rules (https://gitlab.com/gitlab-org/gitlab/-/issues/362217) -->
  </div>
</template>
