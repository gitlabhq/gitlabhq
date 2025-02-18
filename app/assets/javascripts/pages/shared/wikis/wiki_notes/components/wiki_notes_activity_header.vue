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
  <div
    class="gl-flex gl-flex-col gl-justify-between gl-pb-3 gl-pt-5 sm:gl-flex-row sm:gl-items-center"
  >
    <h2 class="gl-m-0 gl-text-size-h1">{{ $options.i18n.headerText }}</h2>
  </div>
</template>
