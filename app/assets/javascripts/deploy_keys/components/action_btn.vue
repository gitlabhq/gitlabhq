<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    deployKey: {
      type: Object,
      required: true,
    },
    category: {
      type: String,
      required: false,
      default: 'tertiary',
    },
    variant: {
      type: String,
      required: false,
      default: 'default',
    },
    icon: {
      type: String,
      required: false,
      default: '',
    },
    mutation: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    doAction() {
      this.isLoading = true;
      this.$apollo
        .mutate({
          mutation: this.mutation,
          variables: { id: this.deployKey.id },
        })
        .catch((error) => this.$emit('error', error))
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <gl-button
    v-bind="$attrs"
    :category="category"
    :variant="variant"
    :icon="icon"
    :loading="isLoading"
    class="btn"
    @click="doAction"
  >
    <slot></slot>
  </gl-button>
</template>
