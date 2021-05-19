<script>
import { GlButton } from '@gitlab/ui';
import eventHub from '../eventhub';

export default {
  components: {
    GlButton,
  },
  props: {
    deployKey: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
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
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    doAction() {
      this.isLoading = true;

      eventHub.$emit(`${this.type}.key`, this.deployKey, () => {
        this.isLoading = false;
      });
    },
  },
};
</script>

<template>
  <gl-button
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
