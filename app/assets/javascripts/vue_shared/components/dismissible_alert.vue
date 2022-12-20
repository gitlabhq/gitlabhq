<script>
import { GlAlert } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';

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
      this.$emit('alertDismissed');
    },
  },
};
</script>

<template>
  <gl-alert v-if="!isDismissed" v-bind="$attrs" @dismiss="dismiss" v-on="$listeners">
    <div v-safe-html="html"></div>
  </gl-alert>
</template>
