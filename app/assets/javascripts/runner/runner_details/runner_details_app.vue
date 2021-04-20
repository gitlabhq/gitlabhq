<script>
import { I18N_TITLE } from './constants';

export default {
  i18n: {
    I18N_TITLE,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <h2 class="page-title">
    {{ sprintf($options.i18n.I18N_TITLE, { runner_id: runnerId }) }}
  </h2>
</template>
