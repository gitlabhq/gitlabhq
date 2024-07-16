<script>
// NOTE 1: This modal directly uses the reCAPTCHA Javascript API
// (https://developers.google.com/recaptcha/docs/display#js_api) and gl-modal,
// rather than relying form-based reCAPTCHA HTML being pre-rendered by the backend.

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
    showModal: {
      type: Boolean,
      required: false,
      default: true,
    },
    resetSession: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      modalId: uniqueId('captcha-modal-'),
      captcha: null,
    };
  },
  watch: {
    needsCaptchaResponse(newNeedsCaptchaResponse) {
      // If this is true, we need to present the captcha modal to the user.
      // When the modal is shown we will also initialize and render the form.
      if (newNeedsCaptchaResponse) {
        this.renderCaptcha();
      }
    },
    resetSession: {
      immediate: true,
      handler(reset) {
        if (reset && this.captcha) {
          this.resetCaptcha();
        }
      },
    },
  },
  mounted() {
    // If this is true, we need to present the captcha modal to the user.
    // When the modal is shown we will also initialize and render the form.
    if (this.needsCaptchaResponse) {
      this.renderCaptcha();
    }
  },
  methods: {
    emitReceivedCaptchaResponse(captchaResponse) {
      if (this.showModal) this.$refs.modal.hide();
      this.$emit('receivedCaptchaResponse', captchaResponse);
    },
    emitNullReceivedCaptchaResponse() {
      this.emitReceivedCaptchaResponse(null);
    },
    renderCaptcha() {
      if (this.showModal) {
        this.$refs.modal.show();
      } else {
        this.initCaptcha();
      }
    },
    /**
     * handler for when modal is shown
     */
    initCaptcha() {
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

          this.captcha = grecaptcha;
        })
        .catch((e) => {
          // TODO: flash the error or notify the user some other way
          //   See https://gitlab.com/gitlab-org/gitlab/-/issues/217722#future-follow-on-issuesmrs
          this.emitNullReceivedCaptchaResponse();

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
    resetCaptcha() {
      this.captcha.reset();
    },
  },
};
</script>
<template>
  <!-- Note: The action-cancel button isn't necessary for the functionality of the modal, but   -->
  <!-- there must be at least one button or focusable element, or the gl-modal fails to render. -->
  <!-- We could modify gl-model to remove this requirement.                                     -->
  <gl-modal
    v-if="showModal"
    ref="modal"
    :modal-id="modalId"
    :title="__('Please solve the captcha')"
    :action-cancel="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
      text: __('Cancel'),
    } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
    @shown="initCaptcha"
    @hide="hide"
    @hidden="$emit('hidden')"
  >
    <div ref="captcha"></div>
    <p>{{ __('We want to be sure it is you, please confirm you are not a robot.') }}</p>
  </gl-modal>
  <div v-else ref="captcha" class="gl-inline-block"></div>
</template>
