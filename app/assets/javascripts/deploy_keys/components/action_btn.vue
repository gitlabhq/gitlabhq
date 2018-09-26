<script>
import eventHub from '../eventhub';
import { LoadingIcon } from '@gitlab-org/gitlab-ui';

export default {
  components: {
    'gl-loading-icon': LoadingIcon,
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
    btnCssClass: {
      type: String,
      required: false,
      default: 'btn-default',
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
  <button
    :class="[{ disabled: isLoading }, btnCssClass]"
    :disabled="isLoading"
    class="btn"
    @click="doAction">
    <slot></slot>
    <gl-loading-icon
      v-if="isLoading"
      :inline="true"
    />
  </button>
</template>
