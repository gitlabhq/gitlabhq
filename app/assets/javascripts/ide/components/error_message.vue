<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
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
    variant="danger"
    :dismissible="canDismiss"
    :primary-button-text="message.actionText"
    @dismiss="dismiss"
    @primaryAction="doAction"
  >
    <span v-safe-html="message.text"></span>
    <gl-loading-icon v-show="isLoading" size="sm" inline class="vertical-align-middle ml-1" />
  </gl-alert>
</template>
