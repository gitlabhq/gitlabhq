<script>
import { mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
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
  methods: {
    ...mapActions(['setErrorMessage']),
    clickAction() {
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
    clickFlash() {
      if (!this.message.action) {
        this.setErrorMessage(null);
      }
    },
  },
};
</script>

<template>
  <div class="flash-container flash-container-page" @click="clickFlash">
    <div class="flash-alert" data-qa-selector="flash_alert">
      <span v-html="message.text"> </span>
      <button
        v-if="message.action"
        type="button"
        class="flash-action text-white p-0 border-top-0 border-right-0 border-left-0 bg-transparent"
        @click.stop.prevent="clickAction"
      >
        {{ message.actionText }}
        <gl-loading-icon v-show="isLoading" inline />
      </button>
    </div>
  </div>
</template>
