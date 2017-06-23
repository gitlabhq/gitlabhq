<script>
/* eslint-disable no-new, no-alert */

import eventHub from '../event_hub';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import tooltipMixin from '../../vue_shared/mixins/tooltip';

export default {
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
  components: {
    loadingIcon,
  },
  mixins: [
    tooltipMixin,
  ],
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

      $(this.$refs.tooltip).tooltip('destroy');
      eventHub.$emit('postAction', this.endpoint);
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
    ref="tooltip"
    :disabled="isLoading">
    <i
      :class="iconClass"
      aria-hidden="true">
    </i>
    <loading-icon v-if="isLoading" />
  </button>
</template>
