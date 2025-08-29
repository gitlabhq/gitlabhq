<script>
import { GlAlert } from '@gitlab/ui';

export default {
  name: 'ErrorsAlert',
  components: {
    GlAlert,
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
    :title="title"
    :class="alertClass"
    variant="danger"
    @dismiss="$emit('dismiss')"
  >
    <span v-if="errors.length === 1">
      {{ errors[0] }}
    </span>
    <ul v-else class="!gl-mb-0 gl-pl-5">
      <li v-for="(error, index) in errors" :key="index">
        {{ error }}
      </li>
    </ul>
  </gl-alert>
</template>
