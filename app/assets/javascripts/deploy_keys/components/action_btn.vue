<script>
  import eventHub from '../eventhub';

  export default {
    data() {
      return {
        isLoading: false,
      };
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
    methods: {
      doAction() {
        this.isLoading = true;

        eventHub.$emit(`${this.type}.key`, this.deployKey);
      },
    },
    computed: {
      text() {
        return `${this.type.charAt(0).toUpperCase()}${this.type.slice(1)}`;
      },
    },
  };
</script>

<template>
  <button
    class="btn btn-sm prepend-left-10"
    :class="[{ disabled: isLoading }, btnCssClass]"
    :disabled="isLoading"
    @click="doAction">
    {{ text }}
    <i
      v-if="isLoading"
      class="fa fa-spinner fa-spin"
      aria-hidden="true">
    </i>
  </button>
</template>
