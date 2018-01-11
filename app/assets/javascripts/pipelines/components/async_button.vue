<script>
  /* eslint-disable no-alert, vue/require-default-prop */

  import eventHub from '../event_hub';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },

    components: {
      loadingIcon,
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      title: {
        type: String,
        required: true,
      },
      icon: {
        type: String,
        required: true,
      },
      cssClass: {
        type: String,
        required: true,
      },
      confirmActionMessage: {
        type: String,
        required: false,
      },
    },

    data() {
      return {
        isLoading: false,
      };
    },
    computed: {
      iconClass() {
        return `fa fa-${this.icon}`;
      },
      buttonClass() {
        return `btn ${this.cssClass}`;
      },
    },
    methods: {
      onClick() {
        if (this.confirmActionMessage && confirm(this.confirmActionMessage)) {
          this.makeRequest();
        } else if (!this.confirmActionMessage) {
          this.makeRequest();
        }
      },
      makeRequest() {
        this.isLoading = true;

        eventHub.$emit('postAction', this.endpoint);
      },
    },
  };
</script>

<template>
  <button
    v-tooltip
    type="button"
    @click="onClick"
    :class="buttonClass"
    :title="title"
    :aria-label="title"
    data-container="body"
    data-placement="top"
    :disabled="isLoading">
    <i
      :class="iconClass"
      aria-hidden="true">
    </i>
    <loading-icon v-if="isLoading" />
  </button>
</template>
