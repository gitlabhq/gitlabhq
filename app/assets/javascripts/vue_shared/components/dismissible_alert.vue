<script>
import { GlAlert, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';

export default {
  name: 'DismissibleAlert',
  components: {
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  props: {
    html: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isDismissed: false,
    };
  },
  methods: {
    dismiss() {
      this.isDismissed = true;
    },
  },
};
</script>

<template>
  <gl-alert v-if="!isDismissed" v-bind="$attrs" @dismiss="dismiss" v-on="$listeners">
    <div v-safe-html="html"></div>
  </gl-alert>
</template>
