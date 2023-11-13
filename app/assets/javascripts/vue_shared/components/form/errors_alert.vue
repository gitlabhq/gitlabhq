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
};
</script>

<template>
  <gl-alert
    v-if="errors.length"
    class="gl-mb-5"
    :title="title"
    variant="danger"
    @dismiss="$emit('input', [])"
  >
    <ul class="gl-pl-5 gl-mb-0">
      <li v-for="error in errors" :key="error">
        {{ error }}
      </li>
    </ul>
  </gl-alert>
</template>
