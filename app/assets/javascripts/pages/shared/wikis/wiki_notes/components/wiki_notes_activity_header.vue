<script>
import { __ } from '~/locale';

export default {
  i18n: {
    headerText: __('Comments'),
  },
  name: 'WikiNotesActivityHeader',
};
</script>
<template>
  <div class="gl-flex gl-flex-col gl-justify-between gl-pt-5 sm:gl-flex-row sm:gl-items-center">
    <h2 class="gl-heading-2 gl-mb-0 gl-mt-5">{{ $options.i18n.headerText }}</h2>
  </div>
</template>
