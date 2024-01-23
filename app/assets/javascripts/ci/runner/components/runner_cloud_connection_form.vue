<script>
import { s__ } from '~/locale';

export default {
  name: 'RunnerCloudForm',
  i18n: {
    title: s__('Runners|Google Cloud connection'),
  },
};
</script>
<template>
  <div>
    <h2 class="gl-font-size-h2">{{ $options.i18n.title }}</h2>
  </div>
</template>
