<script>
import { __ } from '~/locale';

export default {
  name: 'YourWorkProjectsApp',
  i18n: {
    listText: __('Projects list'),
  },
};
</script>

<template>
  <div>
    <p>{{ $options.i18n.listText }}</p>
  </div>
</template>
