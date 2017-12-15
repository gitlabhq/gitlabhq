<script>
  import eventHub from '../eventhub';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';

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

    components: {
      loadingIcon,
    },

    methods: {
      doAction() {
        this.isLoading = true;

        eventHub.$emit(`${this.type}.key`, this.deployKey, () => {
          this.isLoading = false;
        });
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
    <loading-icon
      v-if="isLoading"
      :inline="true"
    />
  </button>
</template>
