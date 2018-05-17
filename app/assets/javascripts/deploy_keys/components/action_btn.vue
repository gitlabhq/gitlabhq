<script>
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import eventHub from '../eventhub';

export default {
  components: {
    loadingIcon,
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
    class="btn"
    :class="[{ disabled: isLoading }, btnCssClass]"
    :disabled="isLoading"
    @click="doAction">
    <slot></slot>
    <loading-icon
      v-if="isLoading"
      :inline="true"
    />
  </button>
</template>
