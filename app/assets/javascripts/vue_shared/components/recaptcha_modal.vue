<script>
  import modal from './modal.vue';

  export default {
    name: 'RecaptchaModal',

    components: {
      modal,
    },

    props: {
      html: {
        type: String,
        required: false,
        default: '',
      },
    },

    data() {
      return {
        script: {},
        scriptSrc: 'https://www.google.com/recaptcha/api.js',
      };
    },

    watch: {
      html() {
        this.appendRecaptchaScript();
      },
    },

    mounted() {
      window.recaptchaDialogCallback = this.submit.bind(this);
    },

    methods: {
      appendRecaptchaScript() {
        this.removeRecaptchaScript();

        const script = document.createElement('script');
        script.src = this.scriptSrc;
        script.classList.add('js-recaptcha-script');
        script.async = true;
        script.defer = true;

        this.script = script;

        document.body.appendChild(script);
      },

      removeRecaptchaScript() {
        if (this.script instanceof Element) this.script.remove();
      },

      close() {
        this.removeRecaptchaScript();
        this.$emit('close');
      },

      submit() {
        this.$el.querySelector('form').submit();
      },
    },
  };
</script>

<template>
  <modal
    kind="warning"
    class="recaptcha-modal js-recaptcha-modal"
    :hide-footer="true"
    :title="__('Please solve the reCAPTCHA')"
    @cancel="close"
  >
    <div slot="body">
      <p>
        {{ __('We want to be sure it is you, please confirm you are not a robot.') }}
      </p>
      <div
        ref="recaptcha"
        v-html="html"
      >
      </div>
    </div>
  </modal>
</template>
