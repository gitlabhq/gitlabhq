<script>
// NOTE 1: This is similar to recaptcha_modal.vue, but it directly uses the reCAPTCHA Javascript API
// (https://developers.google.com/recaptcha/docs/display#js_api) and gl-modal, rather than relying
// on the form-based ReCAPTCHA HTML being pre-rendered by the backend and using deprecated-modal.

// NOTE 2: Even though this modal currently only supports reCAPTCHA, we use 'captcha' instead
// of 'recaptcha' throughout the code, so that we can easily add support for future alternative
// captcha implementations other than reCAPTCHA (e.g. FriendlyCaptcha) without having to
// change the references in the code or API.

import { GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { initRecaptchaScript } from '~/captcha/init_recaptcha_script';

export default {
  components: {
    GlModal,
  },
  props: {
    needsCaptchaResponse: {
      type: Boolean,
      required: false,
      default: false,
    },
    captchaSiteKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      modalId: uniqueId('captcha-modal-'),
    };
  },
  watch: {
    needsCaptchaResponse(newNeedsCaptchaResponse) {
      // If this is true, we need to present the captcha modal to the user.
      // When the modal is shown we will also initialize and render the form.
      if (newNeedsCaptchaResponse) {
        this.$refs.modal.show();
      }
    },
  },
  mounted() {
    // If this is true, we need to present the captcha modal to the user.
    // When the modal is shown we will also initialize and render the form.
    if (this.needsCaptchaResponse) {
      this.$refs.modal.show();
    }
  },
  methods: {
    emitReceivedCaptchaResponse(captchaResponse) {
      this.$refs.modal.hide();
      this.$emit('receivedCaptchaResponse', captchaResponse);
    },
    emitNullReceivedCaptchaResponse() {
      this.emitReceivedCaptchaResponse(null);
    },
    /**
     * handler for when modal is shown
     */
    shown() {
      const containerRef = this.$refs.captcha;

      // NOTE: This is the only bit that is specific to Google's reCAPTCHA captcha implementation.
      initRecaptchaScript()
        .then((grecaptcha) => {
          grecaptcha.render(containerRef, {
            sitekey: this.captchaSiteKey,
            // This callback will emit and let the parent handle the response
            callback: this.emitReceivedCaptchaResponse,
            // TODO: Also need to handle expired-callback and error-callback
            //   See https://gitlab.com/gitlab-org/gitlab/-/issues/217722#future-follow-on-issuesmrs
          });
        })
        .catch((e) => {
          // TODO: flash the error or notify the user some other way
          //   See https://gitlab.com/gitlab-org/gitlab/-/issues/217722#future-follow-on-issuesmrs
          this.emitNullReceivedCaptchaResponse();
          this.$refs.modal.hide();

          // eslint-disable-next-line no-console
          console.error(
            '[gitlab] an unexpected exception was caught while initializing captcha',
            e,
          );
        });
    },
    /**
     * handler for when modal is about to hide
     */
    hide(bvModalEvent) {
      // If hide() was called without any argument, the value of trigger will be null.
      // See https://bootstrap-vue.org/docs/components/modal#prevent-closing
      if (bvModalEvent.trigger) {
        this.emitNullReceivedCaptchaResponse();
      }
    },
  },
};
</script>
<template>
  <!-- Note: The action-cancel button isn't necessary for the functionality of the modal, but   -->
  <!-- there must be at least one button or focusable element, or the gl-modal fails to render. -->
  <!-- We could modify gl-model to remove this requirement.                                     -->
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :title="__('Please solve the captcha')"
    :action-cancel="{ text: __('Cancel') }"
    @shown="shown"
    @hide="hide"
    @hidden="$emit('hidden')"
  >
    <div ref="captcha"></div>
    <p>{{ __('We want to be sure it is you, please confirm you are not a robot.') }}</p>
  </gl-modal>
</template>
