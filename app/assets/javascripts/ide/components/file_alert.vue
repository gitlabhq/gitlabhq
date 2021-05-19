<script>
import { GlAlert } from '@gitlab/ui';
import { getAlert } from '../lib/alerts';

export default {
  components: {
    GlAlert,
  },
  props: {
    alertKey: {
      type: Symbol,
      required: true,
    },
  },
  computed: {
    alert() {
      return getAlert(this.alertKey);
    },
  },
};
</script>
<template>
  <gl-alert v-bind="alert.props" @dismiss="alert.dismiss($store)">
    <component :is="alert.message" />
  </gl-alert>
</template>
