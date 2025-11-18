<script>
import { GlAlert } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'ErrorsAlert',
  components: {
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    errors: {
      type: Array,
      required: false,
      default: () => [],
    },
    scrollOnError: {
      type: Boolean,
      required: false,
      default: true,
    },
    alertClass: {
      type: String,
      required: false,
      default: 'gl-mb-5',
    },
  },
  computed: {
    hasErrors() {
      return this.errors.length > 0;
    },
  },
  watch: {
    errors() {
      // Watch for changes in errors and scroll into focus when errors are present
      if (this.scrollOnError && this.hasErrors) {
        this.scrollToAlert();
      }
    },
  },
  methods: {
    scrollToAlert() {
      this.$nextTick(() => {
        this.$refs.alertRef?.$el?.scrollIntoView({
          behavior: 'smooth',
          block: 'center',
        });
      });
    },
  },
};
</script>

<template>
  <gl-alert
    v-if="hasErrors"
    ref="alertRef"
    role="alert"
    :title="title"
    :class="alertClass"
    variant="danger"
    @dismiss="$emit('dismiss')"
  >
    <span v-if="errors.length === 1" v-safe-html="errors[0]"></span>
    <ul v-else class="!gl-mb-0 gl-pl-5">
      <li v-for="(error, index) in errors" :key="index" v-safe-html="error"></li>
    </ul>
  </gl-alert>
</template>
