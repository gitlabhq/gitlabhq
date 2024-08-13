<script>
import { GlAlert } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  components: { GlAlert },
  model: {
    prop: 'errors',
  },
  props: {
    errors: {
      type: Array,
      required: true,
    },
    scrollOnError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return n__(
        'The form contains the following error:',
        'The form contains the following errors:',
        this.errors.length,
      );
    },
  },
  watch: {
    errors() {
      // Watch for changes in errors and scroll into focus when errors are present
      if (this.scrollOnError && this.errors.length) {
        this.scrollToAlert();
      }
    },
  },
  methods: {
    async scrollToAlert() {
      await this.$nextTick();
      this.$refs.alertRef?.$el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    },
  },
};
</script>

<template>
  <gl-alert
    v-if="errors.length"
    ref="alertRef"
    class="gl-mb-5"
    :title="title"
    variant="danger"
    @dismiss="$emit('input', [])"
  >
    <ul class="gl-mb-0 gl-pl-5">
      <li v-for="error in errors" :key="error">
        {{ error }}
      </li>
    </ul>
  </gl-alert>
</template>
