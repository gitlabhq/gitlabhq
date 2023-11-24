<script>
import { s__ } from '~/locale';

export default {
  props: {
    folderName: {
      type: String,
      required: true,
    },
  },
  i18n: {
    pageTitle: s__('Environments|Environments'),
  },
};
</script>
<template>
  <h4 class="gl-font-weight-normal" data-testid="folder-name">
    {{ $options.i18n.pageTitle }} /
    <b>{{ folderName }}</b>
  </h4>
</template>
