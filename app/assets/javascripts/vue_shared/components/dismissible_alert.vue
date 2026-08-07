<script>
import { GlAlert } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

export default {
  name: 'DismissibleAlert',
  components: {
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glListenersMixin],
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
  <gl-alert v-if="!isDismissed" v-bind="$attrs" @dismiss="dismiss" v-on="glListeners()">
    <div v-safe-html="html"></div>
  </gl-alert>
</template>
