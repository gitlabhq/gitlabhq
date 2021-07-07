<script>
/* eslint-disable vue/no-v-html */
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mapActions } from 'vuex';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    canDismiss() {
      return !this.message.action;
    },
  },
  methods: {
    ...mapActions(['setErrorMessage']),
    doAction() {
      if (this.isLoading) return;

      this.isLoading = true;

      this.message
        .action(this.message.actionPayload)
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
        });
    },
    dismiss() {
      this.setErrorMessage(null);
    },
  },
};
</script>

<template>
  <gl-alert
    data-qa-selector="flash_alert"
    variant="danger"
    :dismissible="canDismiss"
    :primary-button-text="message.actionText"
    @dismiss="dismiss"
    @primaryAction="doAction"
  >
    <span v-html="message.text"></span>
    <gl-loading-icon v-show="isLoading" size="sm" inline class="vertical-align-middle ml-1" />
  </gl-alert>
</template>
