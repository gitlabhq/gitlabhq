<script>
/* eslint-disable no-new, no-alert */
/* global Flash */
import '~/flash';
import eventHub from '../event_hub';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  props: {
    endpoint: {
      type: String,
      required: true,
    },

    service: {
      type: Object,
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

  components: {
    loadingIcon,
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
      return `btn has-tooltip ${this.cssClass}`;
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

      $(this.$el).tooltip('destroy');

      this.service.postAction(this.endpoint)
        .then(() => {
          this.isLoading = false;
          eventHub.$emit('refreshPipelines');
        })
        .catch(() => {
          this.isLoading = false;
          new Flash('An error occured while making the request.');
        });
    },
  },
};
</script>

<template>
  <button
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
      aria-hidden="true" />
    <loading-icon v-if="isLoading" />
  </button>
</template>
