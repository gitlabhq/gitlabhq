<script>
import { s__ } from '~/locale';

export default {
  name: 'StorageCounterApp',
  i18n: {
    placeholder: s__('UsageQuota|Usage'),
  },
};
</script>
<template>
  <div>{{ $options.i18n.placeholder }}</div>
</template>
