import recaptchaModal from '../components/recaptcha_modal.vue';

export default {
  data() {
    return {
      showRecaptcha: false,
      recaptchaHTML: '',
    };
  },

  components: {
    recaptchaModal,
  },

  methods: {
    openRecaptcha() {
      this.showRecaptcha = true;
    },

    closeRecaptcha() {
      this.showRecaptcha = false;
    },

    checkForSpam(data) {
      if (!data.recaptcha_html) return data;

      this.recaptchaHTML = data.recaptcha_html;

      const spamError = new Error(data.error_message);
      spamError.name = 'SpamError';
      spamError.message = 'SpamError';

      throw spamError;
    },
  },
};
